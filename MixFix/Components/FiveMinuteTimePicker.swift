//
//  FiveMinuteTimePicker.swift
//  MixFix
//

import SwiftUI

struct FiveMinuteTimePicker: View {
    @Binding var date: Date
    let label: String
    
    @State private var selectedHour: Int = 12
    @State private var selectedMinute: Int = 0
    @State private var selectedPeriod: String = "AM"
    
    private let hours = Array(1...12)
    private let minutes = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]
    private let periods = ["AM", "PM"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 0) {
                // Hour Picker (1-12)
                Picker("Hour", selection: $selectedHour) {
                    ForEach(hours, id: \.self) { hour in
                        Text(String(format: "%d", hour))
                            .tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 60)
                .clipped()
                
                Text(":")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                
                // Minute Picker (5-minute increments)
                Picker("Minute", selection: $selectedMinute) {
                    ForEach(minutes, id: \.self) { minute in
                        Text(String(format: "%02d", minute))
                            .tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 60)
                .clipped()
                
                // AM/PM Picker
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(periods, id: \.self) { period in
                        Text(period)
                            .tag(period)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 60)
                .clipped()
                
                Spacer()
            }
            .frame(height: 100)
        }
        .onAppear {
            updateFromDate()
        }
        .onChange(of: selectedHour) { _, _ in
            updateDate()
        }
        .onChange(of: selectedMinute) { _, _ in
            updateDate()
        }
        .onChange(of: selectedPeriod) { _, _ in
            updateDate()
        }
        .onChange(of: date) { _, _ in
            updateFromDate()
        }
    }
    
    private func updateFromDate() {
        let calendar = Calendar.current
        let hour24 = calendar.component(.hour, from: date)
        let exactMinute = calendar.component(.minute, from: date)
        
        // Convert 24-hour to 12-hour format
        if hour24 == 0 {
            selectedHour = 12
            selectedPeriod = "AM"
        } else if hour24 < 12 {
            selectedHour = hour24
            selectedPeriod = "AM"
        } else if hour24 == 12 {
            selectedHour = 12
            selectedPeriod = "PM"
        } else {
            selectedHour = hour24 - 12
            selectedPeriod = "PM"
        }
        
        // Round to nearest 5-minute increment
        selectedMinute = (exactMinute / 5) * 5
    }
    
    private func updateDate() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Convert 12-hour to 24-hour format
        var hour24 = selectedHour
        if selectedPeriod == "AM" {
            if selectedHour == 12 {
                hour24 = 0
            }
        } else { // PM
            if selectedHour != 12 {
                hour24 = selectedHour + 12
            }
        }
        
        components.hour = hour24
        components.minute = selectedMinute
        if let newDate = calendar.date(from: components) {
            date = newDate
        }
    }
}
