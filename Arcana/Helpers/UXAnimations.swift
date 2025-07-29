//
// UXAnimations.swift
// Arcana
//
// Revolutionary fluid animations inspired by Gentler Streak with Claude Desktop aesthetics
// Provides sophisticated motion design that makes AI interactions feel magical and responsive
//

import SwiftUI
import Combine

// MARK: - UX Animations

/// Revolutionary animation system that brings AI interactions to life with sophisticated motion design
/// Inspired by Gentler Streak's fluid animations and Claude Desktop's clean aesthetics
public struct UXAnimations {
    
    // MARK: - Animation Presets
    
    /// Gentle spring animation for general UI interactions
    public static let gentleSpring = Animation.spring(
        response: 0.6,
        dampingFraction: 0.8,
        blendDuration: 0.2
    )
    
    /// Responsive spring for quick interactions
    public static let responsiveSpring = Animation.spring(
        response: 0.3,
        dampingFraction: 0.7,
        blendDuration: 0.1
    )
    
    /// Smooth spring for graceful transitions
    public static let smoothSpring = Animation.spring(
        response: 0.8,
        dampingFraction: 0.9,
        blendDuration: 0.3
    )
    
    /// Bouncy spring for playful interactions
    public static let bouncySpring = Animation.spring(
        response: 0.4,
        dampingFraction: 0.6,
        blendDuration: 0.15
    )
    
    /// Eased animation for smooth transitions
    public static let smoothEase = Animation.easeInOut(duration: 0.4)
    
    /// Quick ease for immediate feedback
    public static let quickEase = Animation.easeOut(duration: 0.2)
    
    /// Slow ease for dramatic effects
    public static let dramaticEase = Animation.easeInOut(duration: 0.8)
    
    // MARK: - Timing Functions
    
    /// Custom timing curve for AI thinking animation
    public static let aiThinkingCurve = Animation.timingCurve(0.25, 0.1, 0.25, 1.0, duration: 1.2)
    
    /// Custom timing curve for message appearance
    public static let messageAppearCurve = Animation.timingCurve(0.0, 0.0, 0.58, 1.0, duration: 0.5)
    
    /// Custom timing curve for workspace transitions
    public static let workspaceTransitionCurve = Animation.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.6)
    
    // MARK: - Complex Animations
    
    /// Staggered animation for multiple elements
    public static func staggered(delay: Double = 0.1, animation: Animation = gentleSpring) -> Animation {
        return animation.delay(delay)
    }
    
    /// Repeating animation for ongoing processes
    public static func repeating(animation: Animation, autoreverses: Bool = true) -> Animation {
        return animation.repeatForever(autoreverses: autoreverses)
    }
    
    /// Chained animation sequence
    public static func sequence(_ animations: [Animation]) -> Animation {
        // For now, return the first animation - would implement proper sequencing
        return animations.first ?? gentleSpring
    }
}

// MARK: - Animation Modifiers

/// Sophisticated animation modifier for enhanced UI interactions
public struct FluidAnimationModifier: ViewModifier {
    let trigger: Bool
    let animation: Animation
    let scale: CGFloat
    let opacity: Double
    let offset: CGSize
    
    public init(
        trigger: Bool,
        animation: Animation = UXAnimations.gentleSpring,
        scale: CGFloat = 1.0,
        opacity: Double = 1.0,
        offset: CGSize = .zero
    ) {
        self.trigger = trigger
        self.animation = animation
        self.scale = scale
        self.opacity = opacity
        self.offset = offset
    }
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(trigger ? scale : 1.0)
            .opacity(trigger ? opacity : 1.0)
            .offset(trigger ? offset : .zero)
            .animation(animation, value: trigger)
    }
}

/// Shimmer animation for loading states
public struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false
    let active: Bool
    let duration: Double
    let opacity: Double
    
    public init(active: Bool = true, duration: Double = 1.5, opacity: Double = 0.3) {
        self.active = active
        self.duration = duration
        self.opacity = opacity
    }
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(opacity),
                                Color.white.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: isAnimating ? 400 : -400)
                    .animation(
                        active ? Animation.linear(duration: duration).repeatForever(autoreverses: false) : .default,
                        value: isAnimating
                    )
            )
            .clipped()
            .onAppear {
                if active {
                    isAnimating = true
                }
            }
            .onChange(of: active) { _, newValue in
                isAnimating = newValue
            }
    }
}

/// Pulse animation for attention-grabbing elements
public struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    let active: Bool
    let scale: CGFloat
    let duration: Double
    
    public init(active: Bool = true, scale: CGFloat = 1.1, duration: Double = 1.0) {
        self.active = active
        self.scale = scale
        self.duration = duration
    }
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? scale : 1.0)
            .animation(
                active ? Animation.easeInOut(duration: duration).repeatForever(autoreverses: true) : .default,
                value: isPulsing
            )
            .onAppear {
                if active {
                    isPulsing = true
                }
            }
            .onChange(of: active) { _, newValue in
                isPulsing = newValue
            }
    }
}

/// Breathing animation for AI presence indication
public struct BreathingModifier: ViewModifier {
    @State private var isBreathing = false
    let active: Bool
    let intensity: Double
    let rate: Double
    
    public init(active: Bool = true, intensity: Double = 0.05, rate: Double = 3.0) {
        self.active = active
        self.intensity = intensity
        self.rate = rate
    }
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(1.0 + (isBreathing ? intensity : 0))
            .opacity(0.8 + (isBreathing ? 0.2 : 0))
            .animation(
                active ? Animation.easeInOut(duration: rate).repeatForever(autoreverses: true) : .default,
                value: isBreathing
            )
            .onAppear {
                if active {
                    isBreathing = true
                }
            }
            .onChange(of: active) { _, newValue in
                isBreathing = newValue
            }
    }
}

/// Typewriter animation for text appearance
public struct TypewriterModifier: ViewModifier {
    @State private var displayedText = ""
    @State private var currentIndex = 0
    let text: String
    let speed: Double
    let trigger: Bool
    
    public init(text: String, speed: Double = 0.05, trigger: Bool = true) {
        self.text = text
        self.speed = speed
        self.trigger = trigger
    }
    
    public func body(content: Content) -> some View {
        Text(displayedText)
            .onAppear {
                if trigger {
                    startTypewriting()
                }
            }
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    startTypewriting()
                } else {
                    resetTypewriting()
                }
            }
            .onChange(of: text) { _, _ in
                resetTypewriting()
                if trigger {
                    startTypewriting()
                }
            }
    }
    
    private func startTypewriting() {
        currentIndex = 0
        displayedText = ""
        typeNextCharacter()
    }
    
    private func typeNextCharacter() {
        guard currentIndex < text.count else { return }
        
        let index = text.index(text.startIndex, offsetBy: currentIndex)
        displayedText = String(text[...index])
        currentIndex += 1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + speed) {
            typeNextCharacter()
        }
    }
    
    private func resetTypewriting() {
        displayedText = ""
        currentIndex = 0
    }
}

/// Morphing animation for shape transitions
public struct MorphingModifier: ViewModifier {
    let progress: Double
    let startShape: AnyShape
    let endShape: AnyShape
    
    public init<S1: Shape, S2: Shape>(progress: Double, from startShape: S1, to endShape: S2) {
        self.progress = progress
        self.startShape = AnyShape(startShape)
        self.endShape = AnyShape(endShape)
    }
    
    public func body(content: Content) -> some View {
        content
            .clipShape(
                MorphingShape(
                    progress: progress,
                    startShape: startShape,
                    endShape: endShape
                )
            )
    }
}

/// Custom morphing shape for smooth transitions
public struct MorphingShape: Shape {
    let progress: Double
    let startShape: AnyShape
    let endShape: AnyShape
    
    public var animatableData: Double {
        get { progress }
        set { }
    }
    
    public func path(in rect: CGRect) -> Path {
        // For now, return a simple interpolation - would implement proper morphing
        if progress < 0.5 {
            return startShape.path(in: rect)
        } else {
            return endShape.path(in: rect)
        }
    }
}

// MARK: - Particle System

/// Particle animation system for magical effects
public struct ParticleSystem: View {
    @State private var particles: [Particle] = []
    @State private var animationTimer: Timer?
    
    let particleCount: Int
    let emissionRate: Double
    let particleLifetime: Double
    let colors: [Color]
    let size: CGSize
    let isActive: Bool
    
    public init(
        particleCount: Int = 50,
        emissionRate: Double = 10.0,
        particleLifetime: Double = 3.0,
        colors: [Color] = [.blue, .purple, .cyan],
        size: CGSize = CGSize(width: 300, height: 300),
        isActive: Bool = true
    ) {
        self.particleCount = particleCount
        self.emissionRate = emissionRate
        self.particleLifetime = particleLifetime
        self.colors = colors
        self.size = size
        self.isActive = isActive
    }
    
    public var body: some View {
        Canvas { context, size in
            for particle in particles {
                let opacity = 1.0 - (particle.age / particleLifetime)
                context.opacity = opacity
                
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: particle.position.x - particle.size / 2,
                        y: particle.position.y - particle.size / 2,
                        width: particle.size,
                        height: particle.size
                    )),
                    with: .color(particle.color)
                )
            }
        }
        .frame(width: size.width, height: size.height)
        .onAppear {
            if isActive {
                startAnimation()
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            updateParticles()
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func updateParticles() {
        // Update existing particles
        particles = particles.compactMap { particle in
            var updatedParticle = particle
            updatedParticle.age += 1.0 / 60.0
            updatedParticle.position.x += updatedParticle.velocity.x
            updatedParticle.position.y += updatedParticle.velocity.y
            updatedParticle.velocity.y += 0.5 // Gravity
            
            return updatedParticle.age < particleLifetime ? updatedParticle : nil
        }
        
        // Emit new particles
        if particles.count < particleCount && Double.random(in: 0...60) < emissionRate {
            emitParticle()
        }
    }
    
    private func emitParticle() {
        let particle = Particle(
            position: CGPoint(
                x: Double.random(in: 0...size.width),
                y: size.height
            ),
            velocity: CGPoint(
                x: Double.random(in: -2...2),
                y: Double.random(in: -5...-1)
            ),
            color: colors.randomElement() ?? .blue,
            size: Double.random(in: 2...6),
            age: 0
        )
        
        particles.append(particle)
    }
}

/// Individual particle for the particle system
public struct Particle {
    var position: CGPoint
    var velocity: CGPoint
    let color: Color
    let size: Double
    var age: Double
}

// MARK: - Interactive Animations

/// Interactive spring animation that responds to user input
public struct InteractiveSpringModifier: ViewModifier {
    @GestureState private var dragOffset: CGSize = .zero
    @State private var position: CGSize = .zero
    
    let stiffness: Double
    let damping: Double
    
    public init(stiffness: Double = 300, damping: Double = 30) {
        self.stiffness = stiffness
        self.damping = damping
    }
    
    public func body(content: Content) -> some View {
        content
            .offset(position)
            .offset(dragOffset)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.8)) {
                            position = .zero
                        }
                    }
            )
    }
}

/// Magnetic attraction animation for UI elements
public struct MagneticModifier: ViewModifier {
    @State private var magneticOffset: CGSize = .zero
    let attractionPoint: CGPoint
    let strength: Double
    let maxDistance: Double
    
    public init(attractionPoint: CGPoint, strength: Double = 0.3, maxDistance: Double = 100) {
        self.attractionPoint = attractionPoint
        self.strength = strength
        self.maxDistance = maxDistance
    }
    
    public func body(content: Content) -> some View {
        content
            .offset(magneticOffset)
            .onAppear {
                calculateMagneticForce()
            }
    }
    
    private func calculateMagneticForce() {
        // Simplified magnetic calculation - would implement proper physics
        let distance = sqrt(pow(attractionPoint.x, 2) + pow(attractionPoint.y, 2))
        
        if distance < maxDistance {
            let force = (maxDistance - distance) / maxDistance * strength
            withAnimation(UXAnimations.gentleSpring) {
                magneticOffset = CGSize(
                    width: attractionPoint.x * force,
                    height: attractionPoint.y * force
                )
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    
    /// Apply fluid animation with customizable parameters
    public func fluidAnimation(
        trigger: Bool,
        animation: Animation = UXAnimations.gentleSpring,
        scale: CGFloat = 1.0,
        opacity: Double = 1.0,
        offset: CGSize = .zero
    ) -> some View {
        modifier(FluidAnimationModifier(
            trigger: trigger,
            animation: animation,
            scale: scale,
            opacity: opacity,
            offset: offset
        ))
    }
    
    /// Apply shimmer loading animation
    public func shimmer(active: Bool = true, duration: Double = 1.5, opacity: Double = 0.3) -> some View {
        modifier(ShimmerModifier(active: active, duration: duration, opacity: opacity))
    }
    
    /// Apply pulse animation
    public func pulse(active: Bool = true, scale: CGFloat = 1.1, duration: Double = 1.0) -> some View {
        modifier(PulseModifier(active: active, scale: scale, duration: duration))
    }
    
    /// Apply breathing animation for AI presence
    public func breathing(active: Bool = true, intensity: Double = 0.05, rate: Double = 3.0) -> some View {
        modifier(BreathingModifier(active: active, intensity: intensity, rate: rate))
    }
    
    /// Apply typewriter text animation
    public func typewriter(text: String, speed: Double = 0.05, trigger: Bool = true) -> some View {
        modifier(TypewriterModifier(text: text, speed: speed, trigger: trigger))
    }
    
    /// Apply morphing shape animation
    public func morphing<S1: Shape, S2: Shape>(
        progress: Double,
        from startShape: S1,
        to endShape: S2
    ) -> some View {
        modifier(MorphingModifier(progress: progress, from: startShape, to: endShape))
    }
    
    /// Apply interactive spring animation
    public func interactiveSpring(stiffness: Double = 300, damping: Double = 30) -> some View {
        modifier(InteractiveSpringModifier(stiffness: stiffness, damping: damping))
    }
    
    /// Apply magnetic attraction animation
    public func magnetic(
        attractionPoint: CGPoint,
        strength: Double = 0.3,
        maxDistance: Double = 100
    ) -> some View {
        modifier(MagneticModifier(
            attractionPoint: attractionPoint,
            strength: strength,
            maxDistance: maxDistance
        ))
    }
    
    /// Apply staggered animation with delay
    public func staggered(delay: Double, animation: Animation = UXAnimations.gentleSpring) -> some View {
        self.animation(animation.delay(delay), value: UUID())
    }
    
    /// Apply smooth appearance animation
    public func smoothAppear(delay: Double = 0) -> some View {
        modifier(FluidAnimationModifier(
            trigger: true,
            animation: UXAnimations.messageAppearCurve.delay(delay),
            scale: 0.95,
            opacity: 0,
            offset: CGSize(width: 0, height: 20)
        ))
    }
    
    /// Apply gentle hover effect
    public func gentleHover() -> some View {
        modifier(HoverEffectModifier())
    }
}

/// Hover effect modifier for macOS interactions
public struct HoverEffectModifier: ViewModifier {
    @State private var isHovered = false
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .brightness(isHovered ? 0.05 : 0.0)
            .animation(UXAnimations.responsiveSpring, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Animation Presets for Specific Use Cases

extension UXAnimations {
    
    /// Animation for AI response appearance
    public static let aiResponseAppear = Animation.spring(response: 0.7, dampingFraction: 0.8)
        .delay(0.1)
    
    /// Animation for message sending
    public static let messageSend = Animation.spring(response: 0.4, dampingFraction: 0.7)
    
    /// Animation for workspace switching
    public static let workspaceSwitch = Animation.spring(response: 0.6, dampingFraction: 0.85)
    
    /// Animation for thread creation
    public static let threadCreate = Animation.spring(response: 0.5, dampingFraction: 0.8)
        .delay(0.05)
    
    /// Animation for settings panel
    public static let settingsPanel = Animation.spring(response: 0.7, dampingFraction: 0.9)
    
    /// Animation for search results
    public static let searchResults = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    /// Animation for performance indicators
    public static let performanceUpdate = Animation.easeInOut(duration: 0.3)
    
    /// Animation for confidence scoring
    public static let confidenceIndicator = Animation.spring(response: 0.8, dampingFraction: 0.9)
        .delay(0.2)
    
    /// Animation for thinking indicator
    public static let aiThinking = Animation.easeInOut(duration: 1.0)
        .repeatForever(autoreverses: true)
    
    /// Animation for error states
    public static let errorIndication = Animation.spring(response: 0.3, dampingFraction: 0.6)
        .delay(0.1)
}

// MARK: - Animation Coordination

/// Coordinates complex animation sequences across multiple views
public class AnimationCoordinator: ObservableObject {
    @Published var currentSequence: AnimationSequence?
    @Published var globalAnimationState: GlobalAnimationState = .idle
    
    private var sequenceTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        setupAnimationCoordination()
    }
    
    /// Start a coordinated animation sequence
    public func startSequence(_ sequence: AnimationSequence) {
        currentSequence = sequence
        globalAnimationState = .animating
        
        executeSequenceStep(0)
    }
    
    /// Stop current animation sequence
    public func stopSequence() {
        sequenceTimer?.invalidate()
        sequenceTimer = nil
        currentSequence = nil
        globalAnimationState = .idle
    }
    
    private func setupAnimationCoordination() {
        // Setup global animation state management
    }
    
    private func executeSequenceStep(_ stepIndex: Int) {
        guard let sequence = currentSequence,
              stepIndex < sequence.steps.count else {
            // Sequence complete
            globalAnimationState = .complete
            currentSequence = nil
            return
        }
        
        let step = sequence.steps[stepIndex]
        
        // Execute step
        DispatchQueue.main.asyncAfter(deadline: .now() + step.delay) {
            // Trigger step animation
            self.executeSequenceStep(stepIndex + 1)
        }
    }
}

/// Animation sequence definition
public struct AnimationSequence {
    public let id: UUID
    public let name: String
    public let steps: [AnimationStep]
    
    public init(name: String, steps: [AnimationStep]) {
        self.id = UUID()
        self.name = name
        self.steps = steps
    }
}

/// Individual animation step
public struct AnimationStep {
    public let delay: TimeInterval
    public let duration: TimeInterval
    public let animation: Animation
    public let targetId: String
    
    public init(delay: TimeInterval, duration: TimeInterval, animation: Animation, targetId: String) {
        self.delay = delay
        self.duration = duration
        self.animation = animation
        self.targetId = targetId
    }
}

/// Global animation states
public enum GlobalAnimationState {
    case idle
    case animating
    case paused
    case complete
}

// MARK: - Performance Optimizations

/// Animation performance monitor
public class AnimationPerformanceMonitor: ObservableObject {
    @Published var frameRate: Double = 60.0
    @Published var animationLoad: Double = 0.0
    @Published var recommendedQuality: AnimationQuality = .high
    
    private var frameTimer: Timer?
    private var frameCount = 0
    private var lastFrameTime = CFAbsoluteTimeGetCurrent()
    
    public init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        frameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateMetrics()
        }
    }
    
    private func updateMetrics() {
        let currentTime = CFAbsoluteTimeGetCurrent()
        let deltaTime = currentTime - lastFrameTime
        lastFrameTime = currentTime
        
        frameRate = 1.0 / deltaTime
        
        // Adjust animation quality based on performance
        if frameRate < 30 {
            recommendedQuality = .low
        } else if frameRate < 45 {
            recommendedQuality = .medium
        } else {
            recommendedQuality = .high
        }
    }
    
    deinit {
        frameTimer?.invalidate()
    }
}

/// Animation quality levels
public enum AnimationQuality: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    public var displayName: String {
        return rawValue.capitalized
    }
    
    public var particleCount: Int {
        switch self {
        case .low: return 10
        case .medium: return 25
        case .high: return 50
        }
    }
    
    public var animationDuration: Double {
        switch self {
        case .low: return 0.2
        case .medium: return 0.4
        case .high: return 0.6
        }
    }
}
