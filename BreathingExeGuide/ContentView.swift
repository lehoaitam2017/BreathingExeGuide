import SwiftUI
import SwiftData
import AudioToolbox
import UIKit
import AVFoundation

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var selectedSession: BreathingSession = .stressReset
    @State private var showSplash = true
    @State private var splashVisible = false

    var body: some View {
        ZStack {
            BreathingBackground()

            TabView(selection: $selectedTab) {
                HomeScreen(selectedTab: $selectedTab, selectedSession: $selectedSession)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(AppTab.home)

                LiveSessionScreen(session: selectedSession)
                    .id(selectedSession.id)
                    .tabItem {
                        Label("Sessions", systemImage: "waveform.path.ecg")
                    }
                    .tag(AppTab.sessions)

                ProgressScreen()
                    .tabItem {
                        Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(AppTab.progress)

                SettingsScreen()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(AppTab.settings)
            }
            .tint(BreathingPalette.softBlue)

            if showSplash {
                SplashScreen(isVisible: splashVisible)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            guard showSplash else { return }
            withAnimation(.easeOut(duration: 0.5)) {
                splashVisible = true
            }

            try? await Task.sleep(for: .seconds(1.5))

            withAnimation(.easeInOut(duration: 0.5)) {
                splashVisible = false
            }

            try? await Task.sleep(for: .seconds(0.5))
            showSplash = false
        }
    }
}

private enum SettingsKeys {
    static let soundEnabled = "settings.soundEnabled"
    static let hapticsEnabled = "settings.hapticsEnabled"
    static let voiceGuidanceEnabled = "settings.voiceGuidanceEnabled"
}

private enum AppTab {
    case home
    case sessions
    case progress
    case settings
}

private struct HomeScreen: View {
    @Binding var selectedTab: AppTab
    @Binding var selectedSession: BreathingSession

    private let quickStarts: [QuickStart] = [
        QuickStart(title: "Calm", icon: "water.waves", session: .calmBreathing),
        QuickStart(title: "Focus", icon: "scope", session: .boxBreathing),
        QuickStart(title: "Sleep", icon: "moon.stars.fill", session: .sleepWindDown)
    ]

    private let sessions: [BreathingSession] = [
        .boxBreathing,
        .relax478,
        .stressReset,
        .sleepWindDown
    ]

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Take a breath")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(BreathingPalette.primaryText)
                        Text("Choose a session for this moment")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(BreathingPalette.secondaryText)
                    }

                    HeroCard()

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Quick Start")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(BreathingPalette.primaryText)

                        HStack(spacing: 12) {
                            ForEach(quickStarts) { item in
                                Button {
                                    selectedSession = item.session
                                    selectedTab = .sessions
                                } label: {
                                    VStack(alignment: .leading, spacing: 18) {
                                        Image(systemName: item.icon)
                                            .font(.system(size: 18, weight: .semibold))
                                        Text(item.title)
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundStyle(BreathingPalette.primaryText)
                                    .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
                                    .padding(18)
                                    .background(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .fill(BreathingPalette.card.opacity(0.92))
                                    )
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .stroke(item.session.accent.opacity(0.45), lineWidth: 1)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Exercises")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(BreathingPalette.primaryText)

                        ForEach(sessions) { session in
                            Button {
                                selectedSession = session
                                selectedTab = .sessions
                            } label: {
                                SessionCard(session: session)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 120)
            }
            .scrollContentBackground(.hidden)
        }
    }
}

private struct HeroCard: View {
    var body: some View {
        VStack(spacing: 24) {
            TimelineView(.animation(minimumInterval: 0.05)) { timeline in
                BreathingOrb(
                    progress: HeroOrbMetrics.progress(at: timeline.date),
                    phase: HeroOrbMetrics.phase(at: timeline.date),
                    label: "Ready"
                )
                .frame(height: 240)
            }

            VStack(spacing: 8) {
                Text("Start your calm in one tap")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(BreathingPalette.primaryText)
                Text("Blue leads the inhale. Red guides the release.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(BreathingPalette.secondaryText)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(BreathingPalette.card.opacity(0.95))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [BreathingPalette.deepBlue.opacity(0.7), BreathingPalette.warmRed.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

private struct SessionCard: View {
    let session: BreathingSession

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: session.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: session.icon)
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(session.name)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(BreathingPalette.primaryText)

                HStack(spacing: 10) {
                    Label(session.durationLabel, systemImage: "timer")
                    Text(session.patternDescription)
                }
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(BreathingPalette.secondaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(session.accent)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(BreathingPalette.card.opacity(0.92))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.06), lineWidth: 1)
        }
    }
}

private struct LiveSessionScreen: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKeys.soundEnabled) private var soundEnabled = true
    @AppStorage(SettingsKeys.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(SettingsKeys.voiceGuidanceEnabled) private var voiceGuidanceEnabled = false
    let session: BreathingSession
    @State private var activeStartDate = Date()
    @State private var elapsedBeforeCurrentRun: TimeInterval = 0
    @State private var isPaused = false
    @State private var isEnded = false
    @State private var didPersistCompletion = false
    @State private var lastCuePhase: BreathPhase?
    private let speechSynthesizer = AVSpeechSynthesizer()

    var body: some View {
        NavigationStack {
            TimelineView(.animation(minimumInterval: 0.05)) { timeline in
                let elapsed = elapsedTime(at: timeline.date)
                let state = session.liveState(for: elapsed)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 28) {
                        HStack {
                            Button {
                                restartSession()
                            } label: {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(BreathingPalette.primaryText)
                                    .frame(width: 44, height: 44)
                                    .background(BreathingPalette.card.opacity(0.9), in: Circle())
                            }

                            Spacer()

                            VStack(spacing: 6) {
                                Text(session.name)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundStyle(BreathingPalette.primaryText)
                                Text("Inhale calm. Exhale stress.")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(BreathingPalette.secondaryText)
                            }

                            Spacer()

                            Button {
                                togglePause()
                            } label: {
                                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(BreathingPalette.primaryText)
                                    .frame(width: 44, height: 44)
                                    .background(BreathingPalette.card.opacity(0.9), in: Circle())
                            }
                        }

                        BreathingOrb(
                            progress: state.phaseProgress,
                            phase: state.phase,
                            label: state.phase.label
                        )
                            .frame(height: 360)

                        if isEnded {
                            VStack(spacing: 12) {
                                Text("Well done")
                                    .font(.system(size: 30, weight: .bold, design: .rounded))
                                    .foregroundStyle(BreathingPalette.primaryText)
                                Text("You gave yourself \(session.durationLabel) of calm")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(BreathingPalette.secondaryText)
                                Text("Come back anytime")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(BreathingPalette.secondaryText.opacity(0.9))
                            }
                        } else {
                            VStack(spacing: 14) {
                                Text(state.remainingLabel)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(BreathingPalette.primaryText)

                                HStack(spacing: 18) {
                                    StatPill(title: "Cycle", value: "\(state.cycle)")
                                    StatPill(title: "Pattern", value: session.patternDescription)
                                }

                                if voiceGuidanceEnabled {
                                    Text(state.phase.guidance)
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundStyle(state.phase.gradient[0].opacity(0.95))
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .fill(BreathingPalette.card.opacity(0.95))
                                        )
                                }
                            }
                        }

                        HStack(spacing: 12) {
                            SessionControlButton(
                                title: isPaused ? "Resume" : "Pause",
                                systemImage: isPaused ? "play.fill" : "pause.fill",
                                tint: BreathingPalette.softBlue,
                                action: togglePause
                            )
                            SessionControlButton(
                                title: "Restart",
                                systemImage: "arrow.clockwise",
                                tint: BreathingPalette.secondaryText,
                                action: restartSession
                            )
                            SessionControlButton(
                                title: "End",
                                systemImage: "xmark",
                                tint: BreathingPalette.warmRed,
                                action: { endSession() }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }
                .scrollContentBackground(.hidden)
                .onChange(of: state.isComplete) { _, isComplete in
                    guard isComplete, !isEnded else { return }
                    endSession(markComplete: true)
                }
                .onChange(of: state.phase) { _, phase in
                    triggerPhaseCue(for: phase)
                }
            }
        }
        .onAppear {
            lastCuePhase = nil
        }
    }

    private func elapsedTime(at date: Date) -> TimeInterval {
        if isEnded {
            return TimeInterval(session.duration)
        }

        if isPaused {
            return elapsedBeforeCurrentRun
        }

        return elapsedBeforeCurrentRun + max(0, date.timeIntervalSince(activeStartDate))
    }

    private func togglePause() {
        guard !isEnded else {
            restartSession()
            return
        }

        if isPaused {
            activeStartDate = Date()
            isPaused = false
        } else {
            elapsedBeforeCurrentRun += max(0, Date().timeIntervalSince(activeStartDate))
            isPaused = true
        }
    }

    private func restartSession() {
        elapsedBeforeCurrentRun = 0
        activeStartDate = Date()
        isPaused = false
        isEnded = false
        didPersistCompletion = false
        lastCuePhase = nil
    }

    private func endSession(markComplete: Bool = false) {
        if markComplete {
            elapsedBeforeCurrentRun = TimeInterval(session.duration)
            persistCompletedSessionIfNeeded()
        } else if !isPaused {
            elapsedBeforeCurrentRun = min(
                elapsedBeforeCurrentRun + max(0, Date().timeIntervalSince(activeStartDate)),
                TimeInterval(session.duration)
            )
        }
        isPaused = true
        isEnded = true
    }

    private func persistCompletedSessionIfNeeded() {
        guard !didPersistCompletion else { return }

        let record = SessionRecord(
            sessionName: session.name,
            completedAt: .now,
            durationSeconds: session.duration
        )
        modelContext.insert(record)
        didPersistCompletion = true
    }

    private func triggerPhaseCue(for phase: BreathPhase) {
        guard !isPaused, !isEnded, lastCuePhase != phase else { return }
        lastCuePhase = phase

        if voiceGuidanceEnabled {
            speak(phase.guidance)
        }

        if hapticsEnabled {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.8)
        }

        if soundEnabled {
            AudioServicesPlaySystemSound(1113)
        }
    }

    private func speak(_ phrase: String) {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: phrase)
        utterance.rate = 0.42
        utterance.pitchMultiplier = 0.92
        utterance.volume = 0.8
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }
}

private struct ProgressScreen: View {
    @Query(sort: \SessionRecord.completedAt, order: .reverse) private var records: [SessionRecord]

    var body: some View {
        let summary = ProgressSummary(records: records)

        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Progress")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(BreathingPalette.primaryText)

                    ForEach(summary.stats) { stat in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(stat.title.uppercased())
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(BreathingPalette.secondaryText)
                            Text(stat.value)
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(BreathingPalette.primaryText)
                            Text(stat.detail)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(BreathingPalette.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(22)
                        .background(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .fill(BreathingPalette.card.opacity(0.92))
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [BreathingPalette.softBlue.opacity(0.35), BreathingPalette.warmRed.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    }

                    VStack(alignment: .leading, spacing: 18) {
                        Text("Mood trend")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(BreathingPalette.primaryText)

                        HStack(alignment: .bottom, spacing: 12) {
                            ForEach(Array(summary.weeklyBars.enumerated()), id: \.offset) { index, value in
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: value > 0 && index < 4
                                                ? [BreathingPalette.deepBlue, BreathingPalette.softBlue]
                                                : value > 0
                                                ? [BreathingPalette.warmRed.opacity(0.8), BreathingPalette.softRed]
                                                : [BreathingPalette.card.opacity(0.8), BreathingPalette.card],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .frame(maxWidth: .infinity)
                                    .frame(height: max(18, 140 * value))
                            }
                        }
                        .frame(height: 150, alignment: .bottom)
                    }
                    .padding(22)
                    .background(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(BreathingPalette.card.opacity(0.92))
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 120)
            }
            .scrollContentBackground(.hidden)
        }
    }
}

private struct SettingsScreen: View {
    @AppStorage(SettingsKeys.soundEnabled) private var soundEnabled = true
    @AppStorage(SettingsKeys.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(SettingsKeys.voiceGuidanceEnabled) private var voiceGuidance = false

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Settings")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(BreathingPalette.primaryText)

                    SettingsToggleRow(title: "Sound", subtitle: "Soft tones at each phase change", isOn: $soundEnabled)
                    SettingsToggleRow(title: "Haptics", subtitle: "Gentle taps for inhale and exhale", isOn: $hapticsEnabled)
                    SettingsToggleRow(title: "Voice Guidance", subtitle: "Spoken inhale, hold, exhale cues", isOn: $voiceGuidance)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 120)
            }
            .scrollContentBackground(.hidden)
        }
    }
}

private struct SplashScreen: View {
    let isVisible: Bool

    var body: some View {
        ZStack {
            BreathingBackground()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(BreathingPalette.deepBlue.opacity(0.25))
                        .blur(radius: 22)
                        .frame(width: 170, height: 170)
                        .offset(x: -18, y: -14)

                    Circle()
                        .fill(BreathingPalette.warmRed.opacity(0.22))
                        .blur(radius: 24)
                        .frame(width: 170, height: 170)
                        .offset(x: 20, y: 16)

                    AppIconMark()
                        .frame(width: 120, height: 120)
                        .scaleEffect(isVisible ? 1.0 : 0.86)
                }

                Text("Breathing Exercise Guide")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(BreathingPalette.primaryText)
                Text("Inhale calm. Exhale stress.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(BreathingPalette.secondaryText)
            }
            .opacity(isVisible ? 1.0 : 0.0)
        }
        .ignoresSafeArea()
    }
}

private struct AppIconMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(BreathingPalette.background)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(.white.opacity(0.06), lineWidth: 1)
                }

            Circle()
                .trim(from: 0.08, to: 0.46)
                .stroke(
                    AngularGradient(colors: [BreathingPalette.softBlue, BreathingPalette.deepBlue], center: .center),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-110))
                .padding(22)

            Circle()
                .trim(from: 0.56, to: 0.94)
                .stroke(
                    AngularGradient(colors: [BreathingPalette.softRed, BreathingPalette.warmRed], center: .center),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-110))
                .padding(22)

            Circle()
                .stroke(.white.opacity(0.85), lineWidth: 3)
                .frame(width: 16, height: 16)
        }
    }
}

private struct BreathingOrb: View {
    let progress: Double
    let phase: BreathPhase
    let label: String

    var body: some View {
        let scale = phase.scale(for: progress)
        let colors = phase.gradient
        let clampedIntensity = 0.65

        return ZStack {
            Circle()
                .fill(colors[0].opacity(0.18 + (0.18 * clampedIntensity)))
                .blur(radius: 30 + (28 * clampedIntensity))
                .frame(width: 240, height: 240)
                .scaleEffect(scale * 1.18)

            Circle()
                .fill(colors[1].opacity(0.12 + (0.16 * clampedIntensity)))
                .blur(radius: 38 + (34 * clampedIntensity))
                .frame(width: 280, height: 280)
                .scaleEffect(scale * 1.08)

            Circle()
                .fill(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.16), lineWidth: 1)
                }
                .frame(width: 208, height: 208)
                .scaleEffect(scale)
                .shadow(
                    color: colors[0].opacity(0.2 + (0.45 * clampedIntensity)),
                    radius: 18 + (18 * clampedIntensity),
                    x: 0,
                    y: 18
                )

            VStack(spacing: 8) {
                Text(label)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(phase.prompt)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct StatPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(BreathingPalette.secondaryText)
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(BreathingPalette.primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(BreathingPalette.card.opacity(0.92), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct SessionControlButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(BreathingPalette.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(tint.opacity(0.4), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(BreathingPalette.primaryText)
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(BreathingPalette.secondaryText)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(BreathingPalette.softBlue)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(BreathingPalette.card.opacity(0.92))
        )
    }
}

private struct BreathingBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                BreathingPalette.background,
                Color(red: 15 / 255, green: 23 / 255, blue: 42 / 255),
                Color(red: 9 / 255, green: 13 / 255, blue: 27 / 255)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(BreathingPalette.deepBlue.opacity(0.22))
                .blur(radius: 90)
                .frame(width: 260, height: 260)
                .offset(x: -40, y: -20)
        }
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(BreathingPalette.warmRed.opacity(0.14))
                .blur(radius: 90)
                .frame(width: 240, height: 240)
                .offset(x: 50, y: 20)
        }
        .ignoresSafeArea()
    }
}

private enum BreathingPalette {
    static let deepBlue = Color(hex: "2563EB")
    static let softBlue = Color(hex: "60A5FA")
    static let warmRed = Color(hex: "EF4444")
    static let softRed = Color(hex: "F87171")
    static let background = Color(hex: "0F172A")
    static let card = Color(hex: "111827")
    static let primaryText = Color(hex: "F8FAFC")
    static let secondaryText = Color(hex: "CBD5E1")
}

private struct QuickStart: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let session: BreathingSession
}

private struct ProgressStat: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let detail: String
}

private struct ProgressSummary {
    let stats: [ProgressStat]
    let weeklyBars: [Double]

    init(records: [SessionRecord], calendar: Calendar = .current, now: Date = .now) {
        let totalSessions = records.count
        let totalMinutes = records.reduce(0) { $0 + ($1.durationSeconds / 60) }
        let currentStreak = Self.currentStreak(for: records, calendar: calendar, now: now)
        let mostUsed = Self.mostUsedSessionName(from: records)
        let thisWeekMinutes = Self.minutesThisWeek(from: records, calendar: calendar, now: now)

        stats = [
            ProgressStat(
                title: "Current streak",
                value: "\(currentStreak)",
                detail: currentStreak == 1 ? "1 day of steady breathing" : "\(currentStreak) consecutive days of steady breathing"
            ),
            ProgressStat(
                title: "Minutes this week",
                value: "\(thisWeekMinutes)",
                detail: totalMinutes == 0 ? "Complete a session to start tracking" : "\(totalMinutes) total minutes across all sessions"
            ),
            ProgressStat(
                title: "Sessions completed",
                value: "\(totalSessions)",
                detail: "Most used: \(mostUsed)"
            )
        ]
        weeklyBars = Self.weeklyBarValues(from: records, calendar: calendar, now: now)
    }

    private static func currentStreak(for records: [SessionRecord], calendar: Calendar, now: Date) -> Int {
        let days = Set(records.map { calendar.startOfDay(for: $0.completedAt) })
        guard !days.isEmpty else { return 0 }

        var streak = 0
        var day = calendar.startOfDay(for: now)

        if !days.contains(day),
           let yesterday = calendar.date(byAdding: .day, value: -1, to: day),
           days.contains(yesterday) {
            day = yesterday
        }

        while days.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }

        return streak
    }

    private static func minutesThisWeek(from records: [SessionRecord], calendar: Calendar, now: Date) -> Int {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }

        return records
            .filter { weekInterval.contains($0.completedAt) }
            .reduce(0) { $0 + ($1.durationSeconds / 60) }
    }

    private static func mostUsedSessionName(from records: [SessionRecord]) -> String {
        let counts = records.reduce(into: [String: Int]()) { partialResult, record in
            partialResult[record.sessionName, default: 0] += 1
        }

        return counts.max { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key > rhs.key
            }
            return lhs.value < rhs.value
        }?.key ?? "No sessions yet"
    }

    private static func weeklyBarValues(from records: [SessionRecord], calendar: Calendar, now: Date) -> [Double] {
        let today = calendar.startOfDay(for: now)
        let dailyMinutes: [Date: Int] = records.reduce(into: [:]) { partialResult, record in
            let day = calendar.startOfDay(for: record.completedAt)
            partialResult[day, default: 0] += record.durationSeconds / 60
        }

        let days: [Date] = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -(6 - offset), to: today).map { calendar.startOfDay(for: $0) }
        }

        let maxMinutes = max(dailyMinutes.values.max() ?? 0, 1)

        return days.map { day in
            Double(dailyMinutes[day, default: 0]) / Double(maxMinutes)
        }
    }
}

private struct BreathingSession: Identifiable {
    let id = UUID()
    let name: String
    let duration: Int
    let pattern: [BreathSegment]
    let icon: String
    let accent: Color
    let gradient: [Color]

    var durationLabel: String {
        "\(duration / 60) min"
    }

    var patternDescription: String {
        pattern.map(\.display).joined(separator: "•")
    }

    func liveState(at date: Date, from startDate: Date) -> LiveSessionState {
        liveState(for: max(0, date.timeIntervalSince(startDate)))
    }

    func liveState(for elapsed: TimeInterval) -> LiveSessionState {
        let totalDuration = Double(duration)
        let clampedElapsed = min(max(0, elapsed), totalDuration)
        let cycleDuration = pattern.reduce(0) { $0 + $1.seconds }
        let progressInCycle = cycleDuration == 0 ? 0 : clampedElapsed.truncatingRemainder(dividingBy: cycleDuration)
        var running = progressInCycle
        var active = pattern[0]

        for segment in pattern {
            if running <= segment.seconds {
                active = segment
                break
            }
            running -= segment.seconds
        }

        let phaseProgress = active.seconds == 0 ? 0 : running / active.seconds
        let cycle = cycleDuration == 0 ? 1 : Int(clampedElapsed / cycleDuration) + 1
        let remaining = max(0, duration - Int(clampedElapsed))

        return LiveSessionState(
            phase: active.phase,
            phaseProgress: phaseProgress,
            remainingLabel: String(format: "%d:%02d remaining", remaining / 60, remaining % 60),
            cycle: cycle,
            isComplete: clampedElapsed >= totalDuration
        )
    }

    static let calmBreathing = BreathingSession(
        name: "Calm Breathing",
        duration: 120,
        pattern: [
            BreathSegment(phase: .inhale, seconds: 4),
            BreathSegment(phase: .exhale, seconds: 6)
        ],
        icon: "wind",
        accent: BreathingPalette.softBlue,
        gradient: [BreathingPalette.deepBlue, BreathingPalette.softBlue]
    )

    static let boxBreathing = BreathingSession(
        name: "Box Breathing",
        duration: 120,
        pattern: [
            BreathSegment(phase: .inhale, seconds: 4),
            BreathSegment(phase: .hold, seconds: 4),
            BreathSegment(phase: .exhale, seconds: 4),
            BreathSegment(phase: .rest, seconds: 4)
        ],
        icon: "square.dashed",
        accent: BreathingPalette.softBlue,
        gradient: [BreathingPalette.deepBlue, BreathingPalette.softBlue]
    )

    static let relax478 = BreathingSession(
        name: "4-7-8 Relax",
        duration: 180,
        pattern: [
            BreathSegment(phase: .inhale, seconds: 4),
            BreathSegment(phase: .hold, seconds: 7),
            BreathSegment(phase: .exhale, seconds: 8)
        ],
        icon: "sparkles",
        accent: BreathingPalette.softRed,
        gradient: [BreathingPalette.softBlue, BreathingPalette.softRed]
    )

    static let stressReset = BreathingSession(
        name: "Stress Reset",
        duration: 60,
        pattern: [
            BreathSegment(phase: .inhale, seconds: 3),
            BreathSegment(phase: .exhale, seconds: 6)
        ],
        icon: "bolt.heart",
        accent: BreathingPalette.warmRed,
        gradient: [BreathingPalette.deepBlue, BreathingPalette.warmRed]
    )

    static let sleepWindDown = BreathingSession(
        name: "Sleep Wind Down",
        duration: 180,
        pattern: [
            BreathSegment(phase: .inhale, seconds: 4),
            BreathSegment(phase: .hold, seconds: 4),
            BreathSegment(phase: .exhale, seconds: 8)
        ],
        icon: "moon.zzz.fill",
        accent: BreathingPalette.softBlue,
        gradient: [BreathingPalette.deepBlue, BreathingPalette.softBlue]
    )
}

private struct LiveSessionState {
    let phase: BreathPhase
    let phaseProgress: Double
    let remainingLabel: String
    let cycle: Int
    let isComplete: Bool
}

private struct BreathSegment {
    let phase: BreathPhase
    let seconds: Double

    var display: String {
        String(Int(seconds))
    }
}

private enum BreathPhase {
    case inhale
    case hold
    case exhale
    case rest

    var label: String {
        switch self {
        case .inhale: "Inhale"
        case .hold: "Hold"
        case .exhale: "Exhale"
        case .rest: "Let Go"
        }
    }

    var prompt: String {
        switch self {
        case .inhale: "Blue for calm"
        case .hold: "Stay steady"
        case .exhale: "Release warmth"
        case .rest: "Settle softly"
        }
    }

    var guidance: String {
        switch self {
        case .inhale: "Inhale slowly"
        case .hold: "Hold gently"
        case .exhale: "Exhale fully"
        case .rest: "Let go"
        }
    }

    var gradient: [Color] {
        switch self {
        case .inhale:
            [BreathingPalette.deepBlue, BreathingPalette.softBlue]
        case .hold:
            [Color(red: 88 / 255, green: 76 / 255, blue: 182 / 255), Color(red: 126 / 255, green: 105 / 255, blue: 211 / 255)]
        case .exhale:
            [BreathingPalette.warmRed, BreathingPalette.softRed]
        case .rest:
            [BreathingPalette.card, Color.white.opacity(0.22)]
        }
    }

    func scale(for progress: Double) -> Double {
        let eased = 0.5 - 0.5 * cos(progress * .pi)
        return switch self {
        case .inhale:
            0.84 + (eased * 0.28)
        case .hold:
            1.12
        case .exhale:
            1.12 - (eased * 0.28)
        case .rest:
            0.84
        }
    }
}

private enum HeroOrbMetrics {
    static func progress(at date: Date) -> Double {
        let value = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10)
        return value / 10
    }

    static func phase(at date: Date) -> BreathPhase {
        let value = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10)
        return value < 5 ? .inhale : .exhale
    }
}

private extension Color {
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255

        self.init(red: red, green: green, blue: blue)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SessionRecord.self, inMemory: true)
}
