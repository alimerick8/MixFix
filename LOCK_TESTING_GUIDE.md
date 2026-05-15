# Study Session Lock - Testing Guide

## Setup (REQUIRED FIRST)

### 1. Enable Timer Focus Lock Feature
1. Open the app
2. Go to **Profile** tab
3. Scroll to **Timer Focus Lock** toggle
4. **Turn it ON**
5. You'll be prompted to create a 4-digit PIN
6. Enter and confirm your PIN (e.g., `1234`)

**⚠️ The lock button will NOT appear in study sessions unless this setting is enabled!**

---

## Testing the Lock

### 2. Start a Study Session
1. Go to **Study** tab
2. Tap any study block to open **Study Session View**
3. Tap **"Start Session"** to begin the timer

### 3. Lock the Session
1. Look for the **lock icon** button (between Pause and End Session)
2. Tap the lock icon
3. It should turn **red** and change to a **closed lock** icon
4. **Debug logs should show:**
   ```
   🔒 StudySession: Lock toggle tapped. Current state: isLockedSession=false, focusLockEnabled=true
   🔒 StudySession: Locking session immediately (PIN exists)
   🔒 LockContainer: isLockedSession changed from false to true
   ```

### 4. Verify Lock Enforcement

**The overlay should now appear:**
- Entire screen should be **blurred**
- **Black overlay** (70% opacity) covering everything
- **Lock icon** and "Study Session Locked" message
- **"Unlock" button**

**Try these escape attempts (all should be blocked):**

#### A. Tab Switching
- Tap **Home** tab → ❌ Blocked, haptic feedback, stays on Study tab
- Tap **Profile** tab → ❌ Blocked, haptic feedback, stays on Study tab

#### B. Close/Back Navigation
- Swipe down to dismiss → ❌ Blocked (sheet won't dismiss)
- Tap outside modal → ❌ Blocked (overlay catches taps)

#### C. End Session
- Tap **"End Session"** button → ❌ Should show PIN prompt (StudySessionView's own gate)

#### D. App Backgrounding
1. Swipe up to home screen (iOS allows this)
2. Tap app icon to return
3. **Result:** Blocking overlay + PIN prompt should appear immediately

---

## Expected Behavior

### When Locked:
✅ **Entire app is disabled and blurred**
✅ **Black overlay blocks all interaction**
✅ **Tab switching blocked with haptic feedback**
✅ **Cannot dismiss study session sheet**
✅ **Cannot end session without PIN**
✅ **Pause/Resume/Reset timer still work** (no PIN required)
✅ **Returning from background shows PIN gate immediately**

### To Unlock:
1. Tap **"Unlock"** button on overlay
2. Enter your 4-digit PIN
3. Tap **"Unlock"** in the sheet
4. Overlay disappears, all navigation restored

---

## Debug Logs to Watch

When locking:
```
🔒 StudySession: Lock toggle tapped. Current state: isLockedSession=false, focusLockEnabled=true
🔒 StudySession: Locking session immediately (PIN exists)
🔒 LockContainer: isLockedSession changed from false to true
🔒 LockContainer: isLocked=true, focusLockEnabled=true, isLockedSession=true
```

When trying to navigate while locked:
```
🔒 LockContainer: isLocked=true, focusLockEnabled=true, isLockedSession=true
(Haptic feedback triggers)
```

When unlocking:
```
🔒 LockContainer: isLockedSession changed from true to false
🔒 LockContainer: isLocked=false, focusLockEnabled=true, isLockedSession=false
```

---

## Troubleshooting

### Lock button doesn't appear
→ **Go to Profile → Enable "Timer Focus Lock" toggle**

### Lock button does nothing when tapped
→ **Check if you created a PIN in settings**

### Overlay doesn't appear when locked
→ **Check debug logs - is `isLockedSession` actually true?**
→ **Is `timerFocusLockEnabled` true in settings?**

### Can still navigate when locked
→ **Check if `LockEnforcementContainer` is wrapping `ContentView` in `MixFixApp.swift`**
→ **Verify both `timerFocusLockEnabled` AND `timerManager.isLockedSession` are true**

---

## Architecture Summary

**Lock State:** `PomodoroTimerManager.isLockedSession` (published, app-wide)

**Lock Enforcement:** `LockEnforcementContainer` wraps entire `ContentView`
- Monitors `isLocked = timerFocusLockEnabled && timerManager.isLockedSession`
- When true: disables content, shows overlay, forces PIN gate

**Session Controls:** `StudySessionView`
- Toggles lock on/off
- Shows PIN creation/entry modals
- Gates Close and End Session actions

**Tab Blocking:** `ContentView`
- Monitors tab selection changes
- Blocks changes when `isLockedSession = true`
- Provides haptic feedback
