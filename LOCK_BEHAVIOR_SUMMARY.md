# Study Session Lock - Final Behavior

## ✅ What Users CAN Do When Locked

**Timer Controls (Always Accessible):**
- ✅ **Pause** the timer
- ✅ **Resume** the timer  
- ✅ **Reset** the timer

These work without requiring a PIN.

---

## 🔒 What Requires PIN When Locked

**1. Unlock the Session (Lock Icon)**
- User taps the lock icon to unlock
- → Shows PIN sheet
- → Must enter correct 4-digit PIN
- → Session unlocks, lock icon turns blue/open

**2. End Session**
- User taps "End Session" button
- → Shows PIN sheet
- → Must enter correct 4-digit PIN
- → Session ends and dismisses

**3. Leave the App**
- User tries to switch tabs (Home/Profile)
- → Tab doesn't change, haptic feedback
- → (No PIN sheet needed, just blocked)

**4. Return from Background**
- User backgrounds the app (swipe home)
- User returns to app
- → PIN sheet appears immediately
- → Must unlock to continue

---

## 📱 PIN Sheet Design

**Appearance:**
- Lock icon (gray, 60pt)
- "Study Session Locked" title
- "Enter your PIN to unlock" subtitle
- Rounded card with:
  - "Focus Session PIN" header
  - Instructions text
  - 4-digit PIN text field
  - Blue "Unlock" button
  - "Cancel" button (only if not locked)

**Behavior:**
- Cannot be dismissed by swiping down
- Must enter correct PIN to proceed
- Shows error message if PIN is wrong
- Clears PIN field on error

---

## 🎯 User Flow Examples

### Example 1: Locking a Session
1. User starts study session
2. Taps lock icon (open lock, blue)
3. If first time: Creates 4-digit PIN
4. Lock icon turns red (closed lock)
5. Session is now locked

### Example 2: Trying to Leave
1. Session is locked (red lock icon)
2. User taps "Home" tab
3. Tab doesn't switch, haptic vibration
4. User remains on study session

### Example 3: Unlocking to End Session
1. Session is locked
2. User taps "End Session"
3. PIN sheet appears
4. User enters correct PIN
5. Session ends and dismisses

### Example 4: Backgrounding App
1. Session is locked
2. User swipes home (iOS allows this)
3. User taps app to return
4. PIN sheet appears immediately
5. User must unlock to continue

---

## 🔧 Technical Implementation

**Lock State:**
- Single source of truth: `PomodoroTimerManager.isLockedSession`
- Feature toggle: `@AppStorage("timerFocusLockEnabled")`
- PIN storage: `@AppStorage("timerLockPIN")`

**Lock Enforcement Levels:**

1. **App Level** (`LockEnforcementContainer`)
   - Wraps entire ContentView
   - Shows PIN sheet on app resume when locked
   - No blocking overlay (removed)

2. **Tab Level** (`ContentView`)
   - Blocks tab switching when locked
   - Provides haptic feedback
   - No PIN sheet (just blocks)

3. **Session Level** (`StudySessionView`)
   - Lock toggle button
   - PIN sheet for unlock/end session
   - Timer controls always accessible

**PIN Sheet Triggers:**
- Lock icon tapped (to unlock)
- End Session button tapped
- App returns from background while locked

**No PIN Required:**
- Pause/Resume/Reset timer
- Viewing the session (just can't leave)
