//
//  ReelCardView.swift
//  MixFix
//

import SwiftUI

struct ReelCardView: View {
    let reel: Reel
    @Binding var isLiked: Bool
    @Binding var isSaved: Bool
    let onLike: () -> Void
    let onSave: () -> Void
    let onMoreLikeThis: () -> Void
    let onLessLikeThis: () -> Void
    let onWhyThis: () -> Void
    
    @State private var showFeedback = false
    @State private var likeAnimation = false
    @State private var showBadge = false
    @State private var showHook = false
    @State private var showInsight = false
    @State private var showAction = false
    @State private var showButtons = false
    @State private var showWhyButton = false
    @State private var showSwipeHint = true
    
    var body: some View {
        ZStack {
            // Background with radial gradient + depth
            ZStack {
                // Base gradient
                LinearGradient(
                    colors: reel.type.gradientColors.map { Color(hex: $0) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Radial glow (brighter in center)
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.15),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 100,
                    endRadius: 400
                )
                
                // Subtle noise texture
                Rectangle()
                    .fill(Color.white.opacity(0.03))
                    .blendMode(.overlay)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top: Category badge (interactive, glassmorphic)
                HStack {
                    CategoryBadge(type: reel.type)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .opacity(showBadge ? 1 : 0)
                .offset(y: showBadge ? 0 : -20)
                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.05), value: showBadge)
                
                // Center: Content with clear hierarchy (vertically centered)
                GeometryReader { geometry in
                    VStack(alignment: .leading, spacing: 24) {
                        // Hook (Large, punchy, emotion-forward)
                        if let title = reel.textTitle {
                            Text(title)
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.leading)
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                .opacity(showHook ? 1 : 0)
                                .offset(y: showHook ? 0 : 30)
                                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1), value: showHook)
                        }
                        
                        // Insight (Medium, credible, supporting fact)
                        Text(reel.textBody)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white.opacity(0.95))
                            .multilineTextAlignment(.leading)
                            .lineSpacing(6)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                            .opacity(showInsight ? 1 : 0)
                            .offset(y: showInsight ? 0 : 30)
                            .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.2), value: showInsight)
                        
                        // Action CTA (Glassmorphic pill, tappable feel)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(reel.actionPrompt)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                ZStack {
                                    // Glassmorphism effect
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.ultraThinMaterial)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color.white.opacity(0.25), Color.white.opacity(0.1)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [Color.white.opacity(0.5), Color.white.opacity(0.2)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1.5
                                                )
                                        )
                                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                }
                            )
                            
                            if let source = reel.sourceLink {
                                Text(source)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .italic()
                            }
                        }
                        .opacity(showAction ? 1 : 0)
                        .offset(y: showAction ? 0 : 30)
                        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.3), value: showAction)
                    }
                    .frame(maxWidth: geometry.size.width * 0.85, alignment: .leading)
                    .frame(maxHeight: .infinity, alignment: .center)
                    .padding(.horizontal, 24)
                }
                
                // Bottom: Feedback chips
                if showFeedback {
                    FeedbackChips(
                        onMoreLikeThis: {
                            onMoreLikeThis()
                            withAnimation {
                                showFeedback = false
                            }
                        },
                        onLessLikeThis: {
                            onLessLikeThis()
                            withAnimation {
                                showFeedback = false
                            }
                        },
                        onWhyThis: onWhyThis
                    )
                    .padding(.bottom, 120)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showFeedback = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14))
                            Text("Why am I seeing this?")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.15))
                        )
                    }
                    .padding(.bottom, 120)
                    .opacity(showWhyButton ? 1 : 0)
                    .offset(y: showWhyButton ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.7), value: showWhyButton)
                }
            }
            
            // Right side: Action buttons (TikTok style with blur)
            VStack(spacing: 28) {
                Spacer()
                
                // Like button with count
                VStack(spacing: 6) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isLiked.toggle()
                            likeAnimation = true
                        }
                        onLike()
                        
                        // Haptic feedback
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            likeAnimation = false
                        }
                    } label: {
                        ZStack {
                            // Blur background
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 52, height: 52)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 26, weight: .medium))
                                .foregroundStyle(isLiked ? .red : .white)
                                .scaleEffect(likeAnimation ? 1.4 : 1.0)
                        }
                    }
                }
                .opacity(showButtons ? 1 : 0)
                .offset(x: showButtons ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.4), value: showButtons)
                
                // Save button
                VStack(spacing: 6) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isSaved.toggle()
                        }
                        onSave()
                        
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    } label: {
                        ZStack {
                            // Blur background
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 52, height: 52)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(isSaved ? .yellow : .white)
                        }
                    }
                    
                    Text("Save")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .opacity(showButtons ? 1 : 0)
                .offset(x: showButtons ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.5), value: showButtons)
            }
            .padding(.trailing, 16)
            .padding(.bottom, 140)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .overlay(
            // Swipe hint (fades after 2 seconds)
            VStack {
                Spacer()
                if showSwipeHint {
                    VStack(spacing: 4) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Swipe")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, 140)
                    .transition(.opacity)
                }
            }
        )
        .onAppear {
            // Trigger staggered entrance animations
            showBadge = true
            showHook = true
            showInsight = true
            showAction = true
            showButtons = true
            showWhyButton = true
            
            // Hide swipe hint after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showSwipeHint = false
                }
            }
        }
        .onDisappear {
            // Reset animations for next reel
            showBadge = false
            showHook = false
            showInsight = false
            showAction = false
            showButtons = false
            showWhyButton = false
            showSwipeHint = true
        }
    }
}

// MARK: - Category Badge
struct CategoryBadge: View {
    let type: Reel.ReelType
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: type.icon)
                .font(.system(size: 13, weight: .semibold))
            Text(type.displayName)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            ZStack {
                // Glassmorphism
                Capsule()
                    .fill(.ultraThinMaterial)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.white.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.5), Color.white.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
        )
    }
}

// MARK: - Feedback Chips
struct FeedbackChips: View {
    let onMoreLikeThis: () -> Void
    let onLessLikeThis: () -> Void
    let onWhyThis: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    onMoreLikeThis()
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.system(size: 14))
                        Text("More like this")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.8))
                    )
                }
                
                Button {
                    onLessLikeThis()
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.thumbsdown.fill")
                            .font(.system(size: 14))
                        Text("Less like this")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.6))
                    )
                }
            }
            
            Button {
                onWhyThis()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                    Text("Why am I seeing this?")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                }
                .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
}
