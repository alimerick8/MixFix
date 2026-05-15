//
//  LaunchScreenView.swift
//  MixFix
//
//  Chaos-to-organization animation launch screen

import SwiftUI
import Foundation

struct LaunchScreenView: View {
    @State private var animationPhase: AnimationPhase = .chaos1
    @State private var showMixFix = false
    @State private var mixFixScale: CGFloat = 0.5
    @State private var mixFixOpacity: Double = 0
    @State private var globalDrift: Double = 0 // drives continuous motion
    
    // Random elements for chaos animation
    @State private var elements: [ChaoticElement] = []
    
    enum AnimationPhase {
        case chaos1      // Full chaos
        case chaos2      // Less chaos
        case chaos3      // Minimal chaos
        case organizing  // Forming circle
        case shrinking   // Circle shrinks
        case popping     // Pop effect
        case reveal      // MixFix revealed
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Premium multi-layer gradient background
                ZStack {
                    // Base gradient
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Overlay gradient for depth
                    RadialGradient(
                        colors: [Color.white.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 400
                    )
                    
                    // Subtle animated shimmer overlay
                    LinearGradient(
                        colors: [Color.white.opacity(0.05), Color.clear, Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .ignoresSafeArea()
                
                // Chaotic elements animation
                if animationPhase != .reveal {
                    ForEach(elements) { element in
                        ChaoticShapeView(
                            element: element,
                            phase: animationPhase,
                            geometry: geometry,
                            globalDrift: globalDrift
                        )
                    }
                }
                
                // Premium MixFix reveal with glassmorphism
                if showMixFix {
                    VStack(spacing: 20) {
                        // Logo with premium styling
                        Text("MixFix")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color.white.opacity(0.95)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 10)
                            .shadow(color: Color.white.opacity(0.3), radius: 5, x: 0, y: -2)
                        
                        // Tagline with glassmorphic background
                        Text(tagline)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .tracking(0.5)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(
                                ZStack {
                                    // Glassmorphic blur effect
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.ultraThinMaterial)
                                        .opacity(0.6)
                                    
                                    // Subtle border
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                }
                            )
                            .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                    }
                    .scaleEffect(mixFixScale)
                    .opacity(mixFixOpacity)
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Reduced number of elements for smoother performance
        elements = (0..<18).map { index in
            ChaoticElement(
                id: index,
                initialX: CGFloat.random(in: 0...1.0),
                initialY: CGFloat.random(in: 0...1.0),
                size: CGFloat.random(in: 14...26),
                rotation: Double.random(in: 0...360),
                shape: ChaoticElement.ShapeType.allCases.randomElement()!,
                color: [Color.white, Color.white.opacity(0.85), Color.white.opacity(0.7), Color.white.opacity(0.5)].randomElement()!
            )
        }
        
        // Smoother continuous drift with interpolating animation
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            globalDrift = 360
        }
        
        // Smoother transitions with spring animations and better timing
        // Chaos 1 -> Organizing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75, blendDuration: 0.3)) {
                animationPhase = .organizing
            }
        }
        
        // Organizing -> Shrinking
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2)) {
                animationPhase = .shrinking
            }
        }
        
        // Shrinking -> Popping
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75, blendDuration: 0.2)) {
                animationPhase = .popping
            }
            
            // MixFix text emerges with smoother spring
            showMixFix = true
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78, blendDuration: 0.2)) {
                mixFixScale = 1.0
                mixFixOpacity = 1.0
            }
        }
        
        // Popping -> Reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            withAnimation(.easeOut(duration: 0.35)) {
                animationPhase = .reveal
            }
        }
    }
    
    // Premium dynamic gradient based on time of day
    private var gradientColors: [Color] {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<8: // Early morning - Warm sunrise
            return [Color(hex: "#FF6B95"), Color(hex: "#FF8E53"), Color(hex: "#FFA07A")]
        case 8..<12: // Morning - Vibrant blue
            return [Color(hex: "#667eea"), Color(hex: "#764ba2"), Color(hex: "#f093fb")]
        case 12..<17: // Afternoon - Fresh teal
            return [Color(hex: "#4facfe"), Color(hex: "#00f2fe"), Color(hex: "#43e97b")]
        case 17..<20: // Evening - Golden hour
            return [Color(hex: "#fa709a"), Color(hex: "#fee140"), Color(hex: "#ffd89b")]
        case 20..<22: // Dusk - Purple twilight
            return [Color(hex: "#a8edea"), Color(hex: "#fed6e3"), Color(hex: "#d299c2")]
        default: // Night - Deep blue
            return [Color(hex: "#0f2027"), Color(hex: "#203a43"), Color(hex: "#2c5364")]
        }
    }
    
    // Dynamic tagline based on time of day
    private var tagline: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12:
            return "Start your day with intention"
        case 12..<17:
            return "Stay focused, stay balanced"
        case 17..<22:
            return "Reflect, recharge, reset"
        default:
            return "Rest well, dream big"
        }
    }
}

// MARK: - Chaotic Element Model
struct ChaoticElement: Identifiable {
    let id: Int
    let initialX: CGFloat
    let initialY: CGFloat
    let size: CGFloat
    let rotation: Double
    let shape: ShapeType
    let color: Color
    
    enum ShapeType: CaseIterable {
        case circle, square, triangle, line
    }
}

// MARK: - Chaotic Shape View
struct ChaoticShapeView: View {
    let element: ChaoticElement
    let phase: LaunchScreenView.AnimationPhase
    let geometry: GeometryProxy
    let globalDrift: Double
    
    var body: some View {
        Group {
            switch element.shape {
            case .circle:
                Circle()
                    .fill(element.color)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: element.color.opacity(0.4), radius: 4, x: 0, y: 2)
            case .square:
                RoundedRectangle(cornerRadius: 6)
                    .fill(element.color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: element.color.opacity(0.4), radius: 4, x: 0, y: 2)
            case .triangle:
                Triangle()
                    .fill(element.color)
                    .overlay(
                        Triangle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: element.color.opacity(0.4), radius: 4, x: 0, y: 2)
            case .line:
                Capsule()
                    .fill(element.color)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: element.color.opacity(0.4), radius: 4, x: 0, y: 2)
            }
        }
        .frame(width: element.size, height: element.size)
        .rotationEffect(.degrees(currentRotation))
        .position(currentPosition)
        .opacity(currentOpacity)
        .scaleEffect(currentScale)
    }
    
    private var currentPosition: CGPoint {
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2
        
        let driftRadians = globalDrift * .pi / 180
        let driftOffset: CGFloat = 12
        
        switch phase {
        case .chaos1, .chaos2, .chaos3:
            // Start scattered across screen, with gentle drift
            return CGPoint(
                x: element.initialX * geometry.size.width + CGFloat(cos(driftRadians)) * driftOffset,
                y: element.initialY * geometry.size.height + CGFloat(sin(driftRadians)) * driftOffset
            )
        case .organizing:
            // Move to organized circle
            let angle = (Double(element.id) / 18.0) * 2 * .pi
            let radius: CGFloat = 100
            return CGPoint(
                x: centerX + CGFloat(cos(angle + driftRadians)) * radius,
                y: centerY + CGFloat(sin(angle + driftRadians)) * radius
            )
        case .shrinking:
            // Circle shrinks
            let angle = (Double(element.id) / 18.0) * 2 * .pi
            let radius: CGFloat = 40
            return CGPoint(
                x: centerX + CGFloat(cos(angle + driftRadians)) * radius,
                y: centerY + CGFloat(sin(angle + driftRadians)) * radius
            )
        case .popping, .reveal:
            // Pop outward then disappear
            let angle = (Double(element.id) / 18.0) * 2 * .pi
            let radius: CGFloat = 150
            return CGPoint(
                x: centerX + CGFloat(cos(angle + driftRadians)) * radius,
                y: centerY + CGFloat(sin(angle + driftRadians)) * radius
            )
        }
    }
    
    private var currentRotation: Double {
        switch phase {
        case .chaos1, .chaos2, .chaos3:
            return element.rotation + globalDrift * 0.3
        case .organizing:
            return element.rotation * 0.5 + globalDrift * 0.2
        case .shrinking:
            return 0
        case .popping:
            return element.rotation * 1.5 + globalDrift * 0.4
        case .reveal:
            return element.rotation * 2 + globalDrift * 0.5
        }
    }
    
    private var currentOpacity: Double {
        switch phase {
        case .chaos1:
            return 1.0
        case .chaos2:
            return 0.8
        case .chaos3:
            return 0.6
        case .organizing:
            return 0.9
        case .shrinking:
            return 0.8
        case .popping:
            return 0.3
        case .reveal:
            return 0
        }
    }
    
    private var currentScale: CGFloat {
        switch phase {
        case .chaos1, .chaos2, .chaos3:
            return 1.0
        case .organizing:
            return 0.8
        case .shrinking:
            return 0.5
        case .popping:
            return 1.5
        case .reveal:
            return 0.1
        }
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    LaunchScreenView()
}
