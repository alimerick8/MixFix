//
//  Theme.swift
//  MixFix
//
//  Centralized theme, colors, haptics
//

import SwiftUI

enum MF {
    static let cornerRadius: CGFloat = 12
    static let smallRadius: CGFloat = 8
    
    // Night mode helper
    static var isNightTime: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 20 || hour < 4
    }
    
    static var primaryTextColor: Color {
        isNightTime ? Color.white : .primary
    }
    
    static var secondaryTextColor: Color {
        isNightTime ? Color.white.opacity(0.8) : .secondary
    }

    // Default gradient (for Profile, Calendar, etc.)
    static let gradient = LinearGradient(
        colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.7), Color.cyan.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Home gradient: gray → blue
    static let homeGradient = LinearGradient(
        colors: [Color(hex: "b0b0b0").opacity(0.7), Color(hex: "3b5998").opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Study gradient: yellow → red
    static let studyGradient = LinearGradient(
        colors: [Color(hex: "FFD700").opacity(0.7), Color(hex: "FF4500").opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Mind gradient: green → blue
    static let mindGradient = LinearGradient(
        colors: [Color(hex: "A3C586").opacity(0.7), Color(hex: "3b5998").opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Profile gradient: purple → pink
    static let profileGradient = LinearGradient(
        colors: [Color(hex: "9D50BB").opacity(0.7), Color(hex: "FF6B9D").opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let bg = Color.white
    static let secondaryBG = Color(uiColor: .secondarySystemBackground)
    static let label = Color.primary

    static func glassBackground() -> some View {
        RoundedRectangle(cornerRadius: MF.cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: MF.cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15))
            )
    }
    
    static var isEveningTime: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 17 && hour < 20
    }
    
    static var isMorningTime: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 4 && hour < 12
    }
    
    @ViewBuilder
    static func appBackground() -> some View {
        let hour = Calendar.current.component(.hour, from: Date())
        if isNightTime {
            StarryNightSky()
        } else if isEveningTime {
            // Evening/Sunset (5pm - 8pm)
            EveningSky()
        } else if hour >= 12 && hour < 17 {
            AfternoonSky()
        } else if isMorningTime {
            MorningSky()
        } else {
            Color.white
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return nil
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        let hex = String(format: "#%02lX%02lX%02lX",
                        lroundf(r * 255),
                        lroundf(g * 255),
                        lroundf(b * 255))
        return hex
    }
}

struct GradientHeader: ViewModifier {
    let title: String
    let subtitle: String?
    let gradient: LinearGradient
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                gradient
                    .ignoresSafeArea(edges: .top)
                    .frame(height: 80)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(.title2, weight: .bold))
                        .foregroundStyle(.white)
                    if let subtitle { Text(subtitle).font(.caption2).foregroundStyle(.white.opacity(0.9)) }
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            content
        }
    }
}

extension View {
    func gradientHeader(title: String, subtitle: String? = nil, gradient: LinearGradient = MF.gradient) -> some View {
        modifier(GradientHeader(title: title, subtitle: subtitle, gradient: gradient))
    }
}

// MARK: - Starry Night Sky Background
struct StarryNightSky: View {
    var body: some View {
        ZStack {
            // Night sky gradient background
            LinearGradient(
                colors: [
                    Color(hex: "#0B1026"),
                    Color(hex: "#1A2847"),
                    Color(hex: "#2C4563")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Stationary stars layer
            Canvas { context, size in
                for _ in 0..<150 {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let starSize = CGFloat.random(in: 1...3)
                    let opacity = Double.random(in: 0.4...1.0)
                    
                    context.opacity = opacity
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: starSize, height: starSize)),
                        with: .color(.white)
                    )
                }
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Fireflies View
struct FirefliesView: View {
    @State private var fireflies: [Firefly] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(fireflies) { firefly in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.yellow.opacity(0.8), Color.yellow.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 8
                            )
                        )
                        .frame(width: 16, height: 16)
                        .position(firefly.position)
                        .opacity(firefly.opacity)
                }
            }
            .onAppear {
                // Create 5-8 fireflies dispersed across the screen
                let count = Int.random(in: 5...8)
                let width = max(geometry.size.width, 400)
                let height = max(geometry.size.height, 800)
                
                fireflies = (0..<count).map { index in
                    // Distribute fireflies more evenly across vertical space
                    let segment = height / CGFloat(count)
                    let baseY = segment * CGFloat(index)
                    
                    return Firefly(
                        position: CGPoint(
                            x: CGFloat.random(in: 50...width - 50),
                            y: baseY + CGFloat.random(in: 0...segment)
                        )
                    )
                }
                animateFireflies(in: CGSize(width: width, height: height))
            }
        }
    }
    
    private func animateFireflies(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            for index in fireflies.indices {
                // Slowly move firefly
                let dx = CGFloat.random(in: -1...1)
                let dy = CGFloat.random(in: -1...1)
                
                var newX = fireflies[index].position.x + dx
                var newY = fireflies[index].position.y + dy
                
                // Keep within bounds
                newX = max(0, min(size.width, newX))
                newY = max(0, min(size.height, newY))
                
                fireflies[index].position = CGPoint(x: newX, y: newY)
                
                // Randomly adjust opacity for glow effect
                if Bool.random() {
                    fireflies[index].opacity = Double.random(in: 0.5...1.0)
                }
            }
        }
    }
}

struct Firefly: Identifiable {
    let id = UUID()
    var position: CGPoint
    var opacity: Double = 0.8
}

// MARK: - Afternoon Sky Background
struct AfternoonSky: View {
    @State private var cloudOffsets: [CGFloat] = []
    @State private var screenWidth: CGFloat = 400
    
    var body: some View {
        ZStack {
            // Blue sky gradient
            LinearGradient(
                colors: [
                    Color(hex: "#E3F2FD"),
                    Color(hex: "#90CAF9"),
                    Color(hex: "#64B5F6")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Animated clouds
            GeometryReader { geometry in
                ForEach(0..<5, id: \.self) { index in
                    Cloud(size: cloudSize(for: index))
                        .offset(
                            x: cloudOffsets.indices.contains(index) ? cloudOffsets[index] : CGFloat.random(in: -100...geometry.size.width),
                            y: cloudY(for: index, in: geometry.size)
                        )
                        .opacity(cloudOpacity(for: index))
                }
                .onAppear {
                    screenWidth = geometry.size.width
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            // Initialize cloud positions with better spacing
            cloudOffsets = (0..<5).map { index in
                CGFloat(index) * 250 - 100
            }
            animateClouds()
        }
    }
    
    private func cloudSize(for index: Int) -> CGSize {
        let sizes: [CGSize] = [
            CGSize(width: 120, height: 60),
            CGSize(width: 100, height: 50),
            CGSize(width: 140, height: 70),
            CGSize(width: 90, height: 45),
            CGSize(width: 110, height: 55),
            CGSize(width: 130, height: 65),
            CGSize(width: 95, height: 48),
            CGSize(width: 115, height: 58)
        ]
        return sizes[index % sizes.count]
    }
    
    private func cloudY(for index: Int, in size: CGSize) -> CGFloat {
        let positions: [CGFloat] = [0.1, 0.25, 0.15, 0.4, 0.2, 0.35, 0.12, 0.3]
        return size.height * positions[index % positions.count]
    }
    
    private func cloudOpacity(for index: Int) -> Double {
        let opacities: [Double] = [0.25, 0.3, 0.2, 0.28, 0.22]
        return opacities[index % opacities.count]
    }
    
    private func animateClouds() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            for index in cloudOffsets.indices {
                cloudOffsets[index] += 0.3
                
                // Reset cloud position when it goes off screen
                if cloudOffsets[index] > screenWidth + 150 {
                    cloudOffsets[index] = -150
                }
            }
        }
    }
}

// MARK: - Cloud Shape
struct Cloud: View {
    let size: CGSize
    
    var body: some View {
        Canvas { context, canvasSize in
            // Create cloud path with smooth curves
            var path = Path()
            
            let baseY = size.height * 0.6
            
            // Start from left
            path.move(to: CGPoint(x: 0, y: baseY))
            
            // Left bump
            path.addQuadCurve(
                to: CGPoint(x: size.width * 0.25, y: baseY - size.height * 0.3),
                control: CGPoint(x: size.width * 0.12, y: baseY - size.height * 0.5)
            )
            
            // Middle bump (tallest)
            path.addQuadCurve(
                to: CGPoint(x: size.width * 0.5, y: baseY - size.height * 0.5),
                control: CGPoint(x: size.width * 0.35, y: baseY - size.height * 0.6)
            )
            
            // Right-middle bump
            path.addQuadCurve(
                to: CGPoint(x: size.width * 0.75, y: baseY - size.height * 0.35),
                control: CGPoint(x: size.width * 0.65, y: baseY - size.height * 0.55)
            )
            
            // Right bump
            path.addQuadCurve(
                to: CGPoint(x: size.width, y: baseY),
                control: CGPoint(x: size.width * 0.88, y: baseY - size.height * 0.45)
            )
            
            // Bottom flat line
            path.addLine(to: CGPoint(x: size.width, y: baseY))
            path.addLine(to: CGPoint(x: 0, y: baseY))
            path.closeSubpath()
            
            // Draw cloud with gradient
            let gradient = Gradient(colors: [
                Color.white,
                Color.white.opacity(0.95),
                Color.white.opacity(0.85)
            ])
            
            context.fill(
                path,
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: size.width * 0.5, y: 0),
                    endPoint: CGPoint(x: size.width * 0.5, y: baseY)
                )
            )
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Evening Sky
struct EveningSky: View {
    @State private var cloudOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Sunset gradient background - sky colors only
            LinearGradient(
                colors: [
                    Color(hex: "#7B8BA3"),  // Blue-gray at top
                    Color(hex: "#9B8BA8"),  // Lavender-gray
                    Color(hex: "#B89BA8"),  // Mauve-pink
                    Color(hex: "#C9A5B5"),  // Dusty rose
                    Color(hex: "#D4B5C4"),  // Light pink
                    Color(hex: "#E0C5D4")   // Very light pink at bottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
            
            // Faint clouds
            GeometryReader { geometry in
                ForEach(0..<6, id: \.self) { index in
                    EveningCloudView(
                        size: CGSize(
                            width: CGFloat.random(in: 120...180),
                            height: CGFloat.random(in: 40...60)
                        )
                    )
                    .offset(
                        x: cloudOffset + CGFloat(index) * geometry.size.width / 3.5,
                        y: geometry.size.height * 0.15 + CGFloat(index) * 60
                    )
                    .opacity(0.45)
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
                    cloudOffset = 400
                }
            }
        }
    }
}

struct EveningCloudView: View {
    let size: CGSize
    
    var body: some View {
        Canvas { context, canvasSize in
            let baseY = size.height * 0.6
            
            var path = Path()
            path.move(to: CGPoint(x: 0, y: baseY))
            
            // Cloud shape with curves
            path.addCurve(
                to: CGPoint(x: size.width * 0.3, y: baseY - size.height * 0.3),
                control1: CGPoint(x: size.width * 0.1, y: baseY),
                control2: CGPoint(x: size.width * 0.2, y: baseY - size.height * 0.4)
            )
            
            path.addCurve(
                to: CGPoint(x: size.width * 0.7, y: baseY - size.height * 0.2),
                control1: CGPoint(x: size.width * 0.5, y: baseY - size.height * 0.5),
                control2: CGPoint(x: size.width * 0.6, y: baseY - size.height * 0.3)
            )
            
            path.addCurve(
                to: CGPoint(x: size.width, y: baseY),
                control1: CGPoint(x: size.width * 0.8, y: baseY - size.height * 0.2),
                control2: CGPoint(x: size.width * 0.9, y: baseY)
            )
            
            path.closeSubpath()
            
            // Draw cloud with soft white
            let gradient = Gradient(colors: [
                Color.white.opacity(0.3),
                Color.white.opacity(0.2),
                Color.white.opacity(0.1)
            ])
            
            context.fill(
                path,
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: size.width * 0.5, y: 0),
                    endPoint: CGPoint(x: size.width * 0.5, y: baseY)
                )
            )
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Morning Sky
struct MorningSky: View {
    @State private var cloudOffsets: [CGFloat] = []
    @State private var birdOffsets: [CGFloat] = []
    @State private var screenWidth: CGFloat = 400
    
    var body: some View {
        ZStack {
            // Morning sky gradient
            LinearGradient(
                colors: [
                    Color(hex: "#87CEEB"), // Sky blue
                    Color(hex: "#B0E0E6"), // Powder blue
                    Color(hex: "#E0F6FF")  // Light blue
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Animated clouds
            GeometryReader { geometry in
                ForEach(0..<4, id: \.self) { index in
                    Cloud(size: cloudSize(for: index))
                        .offset(
                            x: cloudOffsets.indices.contains(index) ? cloudOffsets[index] : CGFloat.random(in: -100...geometry.size.width),
                            y: cloudY(for: index, in: geometry.size)
                        )
                        .opacity(cloudOpacity(for: index))
                }
                
                // Animated birds with flapping wings
                ForEach(0..<3, id: \.self) { index in
                    AnimatedBirdView()
                        .frame(width: 20, height: 15)
                        .offset(
                            x: birdOffsets.indices.contains(index) ? birdOffsets[index] : CGFloat.random(in: -50...geometry.size.width),
                            y: birdY(for: index, in: geometry.size)
                        )
                }
                .onAppear {
                    screenWidth = geometry.size.width
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            // Initialize cloud positions
            cloudOffsets = (0..<4).map { index in
                CGFloat(index) * 300 - 100
            }
            // Initialize bird positions
            birdOffsets = (0..<3).map { index in
                CGFloat(index) * 200 - 50
            }
            animateClouds()
            animateBirds()
        }
    }
    
    private func cloudSize(for index: Int) -> CGSize {
        let sizes: [CGSize] = [
            CGSize(width: 110, height: 55),
            CGSize(width: 130, height: 65),
            CGSize(width: 100, height: 50),
            CGSize(width: 120, height: 60)
        ]
        return sizes[index % sizes.count]
    }
    
    private func cloudY(for index: Int, in size: CGSize) -> CGFloat {
        let positions: [CGFloat] = [0.12, 0.28, 0.18, 0.35]
        return size.height * positions[index % positions.count]
    }
    
    private func cloudOpacity(for index: Int) -> Double {
        let opacities: [Double] = [0.3, 0.25, 0.35, 0.28]
        return opacities[index % opacities.count]
    }
    
    private func birdY(for index: Int, in size: CGSize) -> CGFloat {
        let positions: [CGFloat] = [0.15, 0.25, 0.2]
        return size.height * positions[index % positions.count]
    }
    
    private func animateClouds() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            for index in cloudOffsets.indices {
                cloudOffsets[index] += 0.25
                
                // Reset cloud position when it goes off screen
                if cloudOffsets[index] > screenWidth + 150 {
                    cloudOffsets[index] = -150
                }
            }
        }
    }
    
    private func animateBirds() {
        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            for index in birdOffsets.indices {
                birdOffsets[index] += 0.8
                
                // Reset bird position when it goes off screen
                if birdOffsets[index] > screenWidth + 50 {
                    birdOffsets[index] = -50
                }
            }
        }
    }
}
