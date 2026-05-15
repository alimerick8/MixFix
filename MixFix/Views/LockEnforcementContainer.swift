//
//  LockEnforcementContainer.swift
//  MixFix
//
//  Lock enforcement at app navigation level

import SwiftUI

/// App-level container that enforces study session lock across all navigation
struct LockEnforcementContainer<Content: View>: View {
    @EnvironmentObject var timerManager: PomodoroTimerManager
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("timerFocusLockEnabled") private var timerFocusLockEnabled: Bool = false
    @AppStorage("timerLockPIN") private var timerLockPIN: String = ""
    
    @State private var showUnlockPrompt = false
    @State private var enteredPIN: String = ""
    @State private var showPINError: Bool = false
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        let _ = print("🔒 LockContainer: isLocked=\(isLocked), focusLockEnabled=\(timerFocusLockEnabled), isLockedSession=\(timerManager.isLockedSession)")
        
        content
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // When app becomes active while locked, resume timer and show unlock prompt
            if newPhase == .active, isLocked {
                print("🔒 LockContainer: App resumed while locked, resuming timer")
                timerManager.resumeFromBackground()
                showUnlockPrompt = true
            }
            
            // Pause timer when app backgrounds during locked session
            if oldPhase == .active, newPhase == .background, isLocked {
                print("🔒 LockContainer: App backgrounding during locked session, pausing timer")
                timerManager.pauseForBackground()
            }
            
            // Also handle inactive state (e.g., phone call, control center)
            if oldPhase == .active, newPhase == .inactive, isLocked {
                print("🔒 LockContainer: App inactive during locked session")
                timerManager.pauseForBackground()
            }
            
            // Resume when coming back from inactive
            if oldPhase == .inactive, newPhase == .active, isLocked {
                print("🔒 LockContainer: App active again from inactive state")
                timerManager.resumeFromBackground()
            }
        }
        .onChange(of: timerManager.isLockedSession) { oldValue, newValue in
            print("🔒 LockContainer: isLockedSession changed from \(oldValue) to \(newValue)")
            // When lock state changes, show/hide prompt
            if !newValue {
                // Session unlocked
                showUnlockPrompt = false
            }
        }
        .sheet(isPresented: $showUnlockPrompt) {
            VStack(spacing: 20) {
                Text("Focus Session PIN")
                    .font(.headline)
                
                Text(showPINError
                     ? "Incorrect PIN. Try again."
                     : "Enter your 4-digit PIN to unlock and navigate.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(showPINError ? .red : .secondary)
                
                TextField("4-digit PIN", text: $enteredPIN)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 8)
                
                // Only show Unlock button when locked - no cancel option
                Button("Unlock") {
                    validatePIN()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(24)
            .presentationDetents([.height(280)])
            .interactiveDismissDisabled(true) // Cannot dismiss while locked
        }
    }
    
    private var isLocked: Bool {
        timerFocusLockEnabled && timerManager.isLockedSession
    }
    
    private func validatePIN() {
        // Validate 4-digit numeric PIN
        guard enteredPIN.count == 4, enteredPIN.allSatisfy({ $0.isNumber }) else {
            enteredPIN = ""
            showPINError = true
            return
        }
        
        // Check against stored PIN
        guard !timerLockPIN.isEmpty, enteredPIN == timerLockPIN else {
            enteredPIN = ""
            showPINError = true
            return
        }
        
        // Correct PIN - unlock
        enteredPIN = ""
        showPINError = false
        timerManager.isLockedSession = false
        showUnlockPrompt = false
    }
}
