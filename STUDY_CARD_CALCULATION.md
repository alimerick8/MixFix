# Study Card Calculation System

## Overview
The study card shows **planned study time from your schedule** - how much work you NEED to do today based on assignments, tests, and review sessions.

---

## Unit Consistency Rules

### ✅ **All Internal Calculations: Double Minutes**
- All durations are stored and summed as `Double` (not `Int`)
- Prevents precision loss during aggregation
- Example: `45.5` minutes, not `45` minutes

### ✅ **Duration Derivation: Single Conversion**
```swift
// Derive duration from time interval, convert ONCE
let sessionMinutes = session.endTime.timeIntervalSince(session.startTime) / 60.0
```

### ✅ **Display Conversion: At Render Time Only**
```swift
// Convert to hours ONLY when displaying
private var completedStudyHoursToday: Double {
    return completedStudyMinutesToday / 60.0  // Single conversion point
}
```

---

## Data Flow

```
Calendar Events (Assignments, Tests, Classes)
    ↓
generateTodayStudySchedule()
    ↓
Calculate study blocks with mood-based durations
    ↓
Add review sessions (20 min per class)
    ↓
plannedStudyMinutesToday (Double minutes)
    ↓
plannedStudyHoursToday (Double hours, display only)
    ↓
Study Card UI
```

---

## Card Calculation Logic

### **Location:** `/Views/HomeView.swift`

```swift
private var plannedStudyMinutesToday: Double {
    // Use same logic as AI Study Schedule
    let studyBlocks = generateTodayStudySchedule()
    var totalMinutes = Double(studyBlocks.reduce(0) { $0 + $1.duration })
    
    // Add review blocks (Ebbinghaus principle) if enabled
    if showReviewBlocks {
        let calendar = Calendar.current
        let todayClasses = store.events.filter { 
            calendar.isDateInToday($0.start) && $0.category == "Classes"
        }
        let reviewMinutes = Double(todayClasses.count * 20)
        totalMinutes += reviewMinutes
    }
    
    return totalMinutes  // Returns Double minutes
}
```

---

## Key Principles

### 1. **Schedule-Based Calculation**
- Card shows PLANNED study time from your schedule
- Not completed time (that would show 0 until you study)
- Recalculates when events change

### 2. **Study Schedule Logic**
- Uses same `generateTodayStudySchedule()` as Study tab
- Filters for incomplete assignments, tests, exams
- Applies mood-based duration calculations

### 3. **Review Sessions**
- Adds 20 min per class scheduled today
- Based on Ebbinghaus forgetting curve
- Only if `showReviewBlocks` setting is enabled

### 4. **Consistent Units**
- Internal: Always `Double` minutes
- Display: Convert to hours at render time
- No mixing of units in calculations

---

## Example Calculation

### Scenario: User has assignments and classes scheduled today

**Today's Schedule:**
- 📝 **Worksheet (Economics)** - Due today at 6:50 PM → 15 min (mood-based)
- 📚 **Psych class** - 9:00 AM
- 📝 **Reading assignment** - Due in 2 days → Not included (not urgent)

**Calculation:**
```swift
Study blocks: 1 (Worksheet = 15 min)
Review sessions: 1 class × 20 min = 20 min
Total: 15 + 20 = 35 minutes
```

**Card Display:**
```
35 min
Study time today
From your schedule
```

---

## Debug Output

```
📊 Study Card: Found 1 study blocks + 1 review sessions
   Total: 35.0 min
   Block 1: Worksheet - 15 min
```

---

## When Card Updates

### **Card recalculates automatically when:**
- Calendar events change (assignments added/completed)
- Date changes (new day)
- HomeView appears
- Store.events updates

---

## Benefits

✅ **Immediate Value:** Shows useful info even before studying  
✅ **Accurate:** Uses same logic as AI Study Schedule  
✅ **Consistent:** Double precision throughout  
✅ **Adaptive:** Mood-based duration calculations  
✅ **Complete:** Includes review sessions (Ebbinghaus)  

---

## Summary

The study card shows **how much study time you have planned for today** based on:
- Incomplete assignments, tests, and exams
- Mood-adjusted durations (if mood logged)
- 20-minute review sessions for each class
- Ebbinghaus spaced repetition principles

This gives you a realistic daily study goal **before** you start studying, rather than showing 0 minutes until you complete sessions.
