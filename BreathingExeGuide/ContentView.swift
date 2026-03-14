import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showSplash = true
    @State private var splashVisible = false

    var body: some View {
        ZStack {
            BreathingBackground()

            TabView(selection: $selectedTab) {
                HomeScreen(selectedTab: $selectedTab)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(AppTab.home)

                LiveSessionScreen(session: BreathingSession.stressReset)
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

private enum AppTab {
    case home
    case sessions
    case progress
    case settings
}

private struct HomeScreen: View {
    @Binding var selectedTab: AppTab

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
                            SessionCard(session: session)
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
            BreathingOrb(progress: HeroOrbMetrics.progress(at: Date()), phase: HeroOrbMetrics.phase(at: Date()), label: "Ready")
                .frame(height: 240)

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
    let session: BreathingSession
    @State private var startDate = Date()

    var body: some View {
        NavigationStack {
            TimelineView(.animation(minimumInterval: 0.05)) { timeline in
                let state = session.liveState(at: timeline.date, from: startDate)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 28) {
                        HStack {
                            Button {
                                startDate = Date()
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

                            Button {} label: {
                                Image(systemName: "pause.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(BreathingPalette.primaryText)
                                    .frame(width: 44, height: 44)
                                    .background(BreathingPalette.card.opacity(0.9), in: Circle())
                            }
                        }

                        BreathingOrb(progress: state.phaseProgress, phase: state.phase, label: state.phase.label)
                            .frame(height: 360)

                        VStack(spacing: 14) {
                            Text(state.remainingLabel)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(BreathingPalette.primaryText)

                            HStack(spacing: 18) {
                                StatPill(title: "Cycle", value: "\(state.cycle)")
                                StatPill(title: "Pattern", value: session.patternDescription)
                            }
                        }

                        HStack(spacing: 12) {
                            SessionControlButton(title: "Pause", systemImage: "pause.fill", tint: BreathingPalette.softBlue)
                            SessionControlButton(title: "Restart", systemImage: "arrow.clockwise", tint: BreathingPalette.secondaryText)
                            SessionControlButton(title: "End", systemImage: "xmark", tint: BreathingPalette.warmRed)
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
}

private struct ProgressScreen: View {
    private let stats: [ProgressStat] = [
        ProgressStat(title: "7-day streak", value: "7", detail: "Daily breath sessions"),
        ProgressStat(title: "Minutes this week", value: "42", detail: "Steady calm practice"),
        ProgressStat(title: "Sessions completed", value: "12", detail: "Most used: Box Breathing")
    ]

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Progress")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(BreathingPalette.primaryText)

                    ForEach(stats) { stat in
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
                            ForEach(Array([0.35, 0.5, 0.42, 0.7, 0.82, 0.74, 0.9].enumerated()), id: \.offset) { index, height in
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: index < 4
                                                ? [BreathingPalette.deepBlue, BreathingPalette.softBlue]
                                                : [BreathingPalette.warmRed.opacity(0.8), BreathingPalette.softRed],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 140 * height)
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
    @State private var soundEnabled = true
    @State private var hapticsEnabled = true
    @State private var voiceGuidance = false
    @State private var themeIntensity = 0.65

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

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Theme intensity")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(BreathingPalette.primaryText)
                        Slider(value: $themeIntensity, in: 0.2...1.0)
                            .tint(BreathingPalette.softBlue)
                        Text("Adjust the strength of the blue and red glow.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(BreathingPalette.secondaryText)
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

        return ZStack {
            Circle()
                .fill(colors[0].opacity(0.24))
                .blur(radius: 42)
                .frame(width: 240, height: 240)
                .scaleEffect(scale * 1.18)

            Circle()
                .fill(colors[1].opacity(0.18))
                .blur(radius: 58)
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
                .shadow(color: colors[0].opacity(0.45), radius: 26, x: 0, y: 18)

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

    var body: some View {
        Button {} label: {
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
        let elapsed = max(0, date.timeIntervalSince(startDate))
        let totalDuration = Double(duration)
        let clampedElapsed = min(elapsed, totalDuration)
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
            cycle: cycle
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
        switch self {
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
}
