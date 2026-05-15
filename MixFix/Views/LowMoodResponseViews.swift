//
//  LowMoodResponseViews.swift
//  MixFix
//
//  UI components for low mood responses: Soft/Push mode selection and challenge prompts
//

import SwiftUI

// MARK: - Study Mode Selection Banner (Notification Style)
struct StudyModeSelectionBanner: View {
    let moodName: String
    let onSelectMode: (StudyMode) -> Void
    let onDismiss: () -> Void
    
    enum StudyMode {
        case soft
        case push
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Choose Your Approach")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("You're feeling \(moodName.lowercased()). How would you like to study?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Mode Options
            HStack(spacing: 12) {
                // Soft Mode
                Button {
                    onSelectMode(.soft)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "leaf.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.green)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Soft mode")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            Text("Gentle review")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.green.opacity(0.3), lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                
                // Push Mode
                Button {
                    onSelectMode(.push)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "bolt.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.orange)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Push mode")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            Text("Intense burst")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: -5)
        )
    }
}

// MARK: - Challenge Prompt Alert
struct LowMoodChallengeAlert: View {
    @Environment(\.dismiss) private var dismiss
    let moodName: String
    let onAcceptChallenge: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with gradient
            VStack(spacing: 16) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Challenge Time")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("You've selected '\(moodName)' 4 days in a row. Want to try a 15-minute 'push' block and then re-check how you feel?")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.orange.opacity(0.1), Color.red.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            // Action Buttons
            VStack(spacing: 0) {
                // Primary Action - Accept Challenge
                Button {
                    onAcceptChallenge()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "bolt.fill")
                        Text("Start 15-minute push")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
                .buttonStyle(.plain)
                
                Divider()
                
                // Secondary Action - Decline
                Button {
                    onDecline()
                    dismiss()
                } label: {
                    Text("Not now")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 320)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Preview
#Preview("Study Mode Banner") {
    VStack {
        Spacer()
        StudyModeSelectionBanner(
            moodName: "Overwhelmed",
            onSelectMode: { mode in print("Selected: \(mode)") },
            onDismiss: { print("Dismissed") }
        )
    }
    .ignoresSafeArea()
}

#Preview("Challenge Alert") {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        
        LowMoodChallengeAlert(
            moodName: "Sad",
            onAcceptChallenge: { print("Accepted") },
            onDecline: { print("Declined") }
        )
    }
}
