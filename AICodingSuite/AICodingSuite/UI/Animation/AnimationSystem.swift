//
//  AnimationSystem.swift
//  AI Coding Suite
//
//  Advanced animation system with fluid transitions and micro-interactions
//

import SwiftUI

// MARK: - Animation Presets
enum AppAnimation {
    // Standard animations
    static let quick = Animation.easeInOut(duration: 0.2)
    static let medium = Animation.easeInOut(duration: 0.3)
    static let slow = Animation.easeInOut(duration: 0.5)

    // Spring animations
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let springBouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)

    // Specialized animations
    static let panel = Animation.spring(response: 0.35, dampingFraction: 0.85)
    static let modal = Animation.spring(response: 0.4, dampingFraction: 0.9)
    static let tooltip = Animation.easeOut(duration: 0.15)
    static let glow = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
}

// MARK: - Animated Container
struct AnimatedContainer<Content: View>: View {
    let content: Content
    let animation: Animation
    @State private var isVisible = false

    init(animation: Animation = AppAnimation.spring, @ViewBuilder content: () -> Content) {
        self.animation = animation
        self.content = content()
    }

    var body: some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.95)
            .animation(animation, value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

// MARK: - Shimmer Effect
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    let duration: Double
    let angle: Angle

    init(duration: Double = 2.0, angle: Angle = .degrees(45)) {
        self.duration = duration
        self.angle = angle
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(angle)
                .offset(x: phase * 300 - 150)
                .animation(
                    .linear(duration: duration).repeatForever(autoreverses: false),
                    value: phase
                )
            )
            .onAppear {
                phase = 1
            }
    }
}

// MARK: - Pulse Effect
struct PulseEffect: ViewModifier {
    @State private var isPulsing = false
    let color: Color
    let duration: Double

    init(color: Color, duration: Double = 1.5) {
        self.color = color
        self.duration = duration
    }

    func body(content: Content) -> some View {
        content
            .shadow(
                color: color.opacity(isPulsing ? 0.8 : 0.3),
                radius: isPulsing ? 20 : 8
            )
            .animation(
                .easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - Typing Animation
struct TypingAnimationView: View {
    let text: String
    let speed: Double
    @State private var displayedText = ""
    @State private var currentIndex = 0

    init(_ text: String, speed: Double = 0.05) {
        self.text = text
        self.speed = speed
    }

    var body: some View {
        Text(displayedText)
            .onAppear {
                startTyping()
            }
    }

    private func startTyping() {
        Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { timer in
            if currentIndex < text.count {
                let index = text.index(text.startIndex, offsetBy: currentIndex)
                displayedText.append(text[index])
                currentIndex += 1
            } else {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Particle System
struct ParticleView: View {
    @State private var particles: [Particle] = []
    let particleCount: Int
    let colors: [Color]

    init(count: Int = 20, colors: [Color] = [.blue, .purple, .pink]) {
        self.particleCount = count
        self.colors = colors
    }

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .opacity(particle.opacity)
                    .position(particle.position)
                    .blur(radius: 2)
            }
        }
        .onAppear {
            createParticles()
            animateParticles()
        }
    }

    private func createParticles() {
        particles = (0..<particleCount).map { _ in
            Particle(
                color: colors.randomElement() ?? .blue,
                size: CGFloat.random(in: 2...6),
                position: CGPoint(
                    x: CGFloat.random(in: 0...400),
                    y: CGFloat.random(in: 0...400)
                ),
                opacity: Double.random(in: 0.3...0.8)
            )
        }
    }

    private func animateParticles() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation(.linear(duration: 0.05)) {
                particles = particles.map { particle in
                    var updated = particle
                    updated.position.y -= 1
                    updated.opacity -= 0.01

                    if updated.position.y < 0 {
                        updated.position.y = 400
                        updated.opacity = 0.8
                    }

                    return updated
                }
            }
        }
    }

    struct Particle: Identifiable {
        let id = UUID()
        let color: Color
        let size: CGFloat
        var position: CGPoint
        var opacity: Double
    }
}

// MARK: - Loading States
struct LoadingView: View {
    @State private var rotation: Double = 0
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    LinearGradient(
                        colors: [
                            themeManager.currentTheme.neonAccent,
                            themeManager.currentTheme.neonSecondary
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(rotation))
                .animation(
                    .linear(duration: 1).repeatForever(autoreverses: false),
                    value: rotation
                )
        }
        .onAppear {
            rotation = 360
        }
    }
}

// MARK: - Success Animation
struct SuccessAnimationView: View {
    @State private var checkmarkProgress: CGFloat = 0
    @State private var circleProgress: CGFloat = 0
    @State private var scale: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: circleProgress)
                .stroke(Color.green, lineWidth: 4)
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))

            Path { path in
                path.move(to: CGPoint(x: 20, y: 30))
                path.addLine(to: CGPoint(x: 28, y: 38))
                path.addLine(to: CGPoint(x: 42, y: 22))
            }
            .trim(from: 0, to: checkmarkProgress)
            .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            .frame(width: 60, height: 60)
        }
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                scale = 1
                circleProgress = 1
            }

            withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                checkmarkProgress = 1
            }
        }
    }
}

// MARK: - Skeleton Loading
struct SkeletonView: View {
    @State private var isAnimating = false
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    init(width: CGFloat = 200, height: CGFloat = 20, cornerRadius: CGFloat = 4) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.2),
                        Color.gray.opacity(0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .modifier(ShimmerEffect())
    }
}

// MARK: - View Extensions
extension View {
    func shimmer(duration: Double = 2.0, angle: Angle = .degrees(45)) -> some View {
        modifier(ShimmerEffect(duration: duration, angle: angle))
    }

    func pulse(color: Color, duration: Double = 1.5) -> some View {
        modifier(PulseEffect(color: color, duration: duration))
    }

    func animatedEntry(delay: Double = 0) -> some View {
        modifier(AnimatedEntryModifier(delay: delay))
    }

    func bounceOnAppear() -> some View {
        modifier(BounceModifier())
    }
}

struct AnimatedEntryModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .animation(
                AppAnimation.spring.delay(delay),
                value: isVisible
            )
            .onAppear {
                isVisible = true
            }
    }
}

struct BounceModifier: ViewModifier {
    @State private var scale: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                withAnimation(AppAnimation.springBouncy) {
                    scale = 1
                }
            }
    }
}

// MARK: - Haptic Feedback
enum HapticFeedback {
    static func light() {
        #if os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
        #endif
    }

    static func medium() {
        #if os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
        #endif
    }

    static func heavy() {
        #if os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
        #endif
    }

    static func success() {
        #if os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
        #endif
    }

    static func error() {
        #if os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
        #endif
    }
}
