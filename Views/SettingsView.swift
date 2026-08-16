import SwiftUI
import SwiftData
import WidgetKit
import UserNotifications

// MARK: - Dawnly Theme

private extension Color {

    static let dawnlyOrange = Color(
        red: 1.0,
        green: 0.55,
        blue: 0.15
    )
}

// MARK: - Settings View

struct SettingsView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.colorScheme)
    private var colorScheme

    @AppStorage("defaultFocusDuration")
    private var defaultFocusDuration = 25

    @AppStorage("keepScreenAwake")
    private var keepScreenAwake = false

    @AppStorage("sessionCompletionNotifications")
    private var sessionCompletionNotifications = true

    @AppStorage("notificationSound")
    private var notificationSound = true

    @AppStorage("appearance")
    private var appearance = "system"

    @State private var showingClearHistoryAlert = false
    @State private var showingAbout = false

    var body: some View {

        NavigationStack {

            List {

                // MARK: Focus

                Section {

                    NavigationLink {
                        FocusSettingsView(
                            defaultFocusDuration:
                                $defaultFocusDuration,
                            keepScreenAwake:
                                $keepScreenAwake
                        )
                    } label: {

                        SettingsRow(
                            icon: "timer",
                            title: "Focus",
                            subtitle:
                                "\(defaultFocusDuration) minute default"
                        )
                    }

                } header: {

                    SettingsSectionHeader(
                        title: "Focus"
                    )
                }

                // MARK: Notifications

                Section {

                    Toggle(isOn:
                        $sessionCompletionNotifications
                    ) {

                        SettingsRow(
                            icon: "bell.fill",
                            title: "Session completion",
                            subtitle:
                                "Notify when a focus session ends"
                        )
                    }
                    .tint(Color.dawnlyOrange)

                    Toggle(isOn:
                        $notificationSound
                    ) {

                        SettingsRow(
                            icon: "speaker.wave.2.fill",
                            title: "Notification sound",
                            subtitle:
                                "Play a sound when a session ends"
                        )
                    }
                    .tint(Color.dawnlyOrange)
                    .disabled(
                        !sessionCompletionNotifications
                    )

                } header: {

                    SettingsSectionHeader(
                        title: "Notifications"
                    )
                }

                // MARK: Appearance

                Section {

                    NavigationLink {

                        AppearanceSettingsView(
                            appearance:
                                $appearance
                        )

                    } label: {

                        SettingsRow(
                            icon: "circle.lefthalf.filled",
                            title: "Appearance",
                            subtitle:
                                appearanceDisplayName
                        )
                    }

                } header: {

                    SettingsSectionHeader(
                        title: "Appearance"
                    )
                }

                // MARK: Data

                Section {

                    NavigationLink {

                        DataSettingsView(
                            modelContext:
                                modelContext,
                            showingClearHistoryAlert:
                                $showingClearHistoryAlert
                        )

                    } label: {

                        SettingsRow(
                            icon: "externaldrive.fill",
                            title: "Data",
                            subtitle:
                                dataSummary
                        )
                    }

                } header: {

                    SettingsSectionHeader(
                        title: "Data"
                    )
                }

                // MARK: About

                Section {

                    Button {

                        showingAbout = true

                    } label: {

                        SettingsRow(
                            icon: "info.circle.fill",
                            title: "About Dawnly",
                            subtitle:
                                "Version \(appVersion)"
                        )
                    }
                    .buttonStyle(.plain)

                    Link(
                        destination:
                            URL(
                                string:
                                    "mailto:info@akhinabraham.com"
                            )!
                    ) {

                        SettingsRow(
                            icon: "envelope.fill",
                            title: "Send feedback",
                            subtitle:
                                "Tell us what you think"
                        )
                    }

                } header: {

                    SettingsSectionHeader(
                        title: "About"
                    )
                }

                // MARK: Footer

                Section {

                    VStack(spacing: 8) {

                        Image(
                            systemName:
                                "sun.max.fill"
                        )
                        .font(
                            .system(
                                size: 22,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(
                            Color.dawnlyOrange
                        )

                        Text("Dawnly")
                            .font(
                                .system(
                                    size: 17,
                                    weight: .semibold,
                                    design: .rounded
                                )
                            )

                        Text(
                            "Take a moment to focus."
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )

                    }
                    .frame(
                        maxWidth: .infinity
                    )
                    .padding(.vertical, 18)
                    .listRowBackground(
                        Color.clear
                    )

                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(
                .large
            )
            .scrollContentBackground(
                .hidden
            )
            .background(
                Color(
                    .systemGroupedBackground
                )
            )
            .alert(
                "About Dawnly",
                isPresented:
                    $showingAbout
            ) {

                Button("Done") { }

            } message: {

                Text(
                    """
                    Dawnly

                    A simple focus timer designed to help you slow down, focus, and make progress.

                    Version \(appVersion)
                    """
                )
            }
        }
        .task {

            await requestNotificationPermissionIfNeeded()
        }
    }

    // MARK: Appearance Name

    private var appearanceDisplayName: String {

        switch appearance {

        case "light":
            return "Light"

        case "dark":
            return "Dark"

        default:
            return "System"
        }
    }

    // MARK: Data Summary

    private var dataSummary: String {

        let descriptor =
            FetchDescriptor<FocusSession>()

        do {

            let sessions =
                try modelContext.fetch(
                    descriptor
                )

            let completed =
                sessions.filter {
                    $0.completed
                }

            let total =
                completed.reduce(0) {
                    $0 + $1.duration
                }

            let minutes =
                Int(total / 60)

            if minutes == 0 {
                return "No completed sessions"
            }

            if minutes < 60 {
                return "\(minutes) minutes focused"
            }

            let hours =
                minutes / 60

            let remaining =
                minutes % 60

            if remaining == 0 {
                return "\(hours) hours focused"
            }

            return
                "\(hours)h \(remaining)m focused"

        } catch {

            return "Unable to read data"
        }
    }

    // MARK: App Version

    private var appVersion: String {

        let version =
            Bundle.main.object(
                forInfoDictionaryKey:
                    "CFBundleShortVersionString"
            ) as? String
            ?? "1.0"

        let build =
            Bundle.main.object(
                forInfoDictionaryKey:
                    "CFBundleVersion"
            ) as? String
            ?? "1"

        return "\(version) (\(build))"
    }

    // MARK: Notification Permission

    private func requestNotificationPermissionIfNeeded()
        async {

        guard sessionCompletionNotifications
        else {
            return
        }

        let settings =
            await UNUserNotificationCenter
                .current()
                .notificationSettings()

        guard settings.authorizationStatus
                == .notDetermined
        else {
            return
        }

        do {

            _ = try await
                UNUserNotificationCenter
                    .current()
                    .requestAuthorization(
                        options: [
                            .alert,
                            .sound
                        ]
                    )

        } catch {

            print(
                "Dawnly: Notification permission error: \(error)"
            )
        }
    }
}

// MARK: - Settings Row

private struct SettingsRow: View {

    let icon: String
    let title: String
    let subtitle: String

    var body: some View {

        HStack(spacing: 13) {

            Image(
                systemName: icon
            )
            .font(
                .system(
                    size: 15,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                Color.dawnlyOrange
            )
            .frame(
                width: 30,
                height: 30
            )
            .background(
                Color.dawnlyOrange.opacity(
                    0.10
                ),
                in: RoundedRectangle(
                    cornerRadius: 9,
                    style: .continuous
                )
            )

            VStack(
                alignment: .leading,
                spacing: 2
            ) {

                Text(title)
                    .font(
                        .system(
                            size: 15,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        .primary
                    )

                Text(subtitle)
                    .font(
                        .system(
                            size: 12
                        )
                    )
                    .foregroundStyle(
                        .secondary
                    )
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Section Header

private struct SettingsSectionHeader: View {

    let title: String

    var body: some View {

        Text(title.uppercased())
            .font(
                .system(
                    size: 11,
                    weight: .bold
                )
            )
            .tracking(0.8)
            .foregroundStyle(
                .secondary
            )
    }
}

// MARK: - Focus Settings

private struct FocusSettingsView: View {

    @Binding var defaultFocusDuration: Int
    @Binding var keepScreenAwake: Bool

    private let durations = [
        25,
        50,
        60,
        90
    ]

    var body: some View {

        List {

            Section {

                ForEach(
                    durations,
                    id: \.self
                ) { duration in

                    Button {

                        defaultFocusDuration =
                            duration

                    } label: {

                        HStack {

                            Text(
                                "\(duration) minutes"
                            )
                            .foregroundStyle(
                                .primary
                            )

                            Spacer()

                            if defaultFocusDuration
                                == duration {

                                Image(
                                    systemName:
                                        "checkmark"
                                )
                                .font(
                                    .system(
                                        size: 14,
                                        weight: .semibold
                                    )
                                )
                                .foregroundStyle(
                                    Color.dawnlyOrange
                                )
                            }
                        }
                    }
                }

            } header: {

                Text("Default duration")
            }

            Section {

                Toggle(
                    "Keep screen awake",
                    isOn:
                        $keepScreenAwake
                )
                .tint(
                    Color.dawnlyOrange
                )

            } footer: {

                Text(
                    "Keep the display awake while using the timer."
                )
            }
        }
        .navigationTitle("Focus")
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}

// MARK: - Appearance Settings

private struct AppearanceSettingsView: View {

    @Binding var appearance: String

    var body: some View {

        List {

            Section {

                AppearanceOption(
                    title: "System",
                    icon: "iphone",
                    isSelected:
                        appearance == "system"
                ) {
                    appearance = "system"
                }

                AppearanceOption(
                    title: "Light",
                    icon: "sun.max.fill",
                    isSelected:
                        appearance == "light"
                ) {
                    appearance = "light"
                }

                AppearanceOption(
                    title: "Dark",
                    icon: "moon.fill",
                    isSelected:
                        appearance == "dark"
                ) {
                    appearance = "dark"
                }

            } footer: {

                Text(
                    "System follows your device appearance setting."
                )
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}

// MARK: - Appearance Option

private struct AppearanceOption: View {

    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {

        Button(
            action: action
        ) {

            HStack(spacing: 13) {

                Image(
                    systemName: icon
                )
                .foregroundStyle(
                    Color.dawnlyOrange
                )
                .frame(
                    width: 24
                )

                Text(title)
                    .foregroundStyle(
                        .primary
                    )

                Spacer()

                if isSelected {

                    Image(
                        systemName:
                            "checkmark.circle.fill"
                    )
                    .foregroundStyle(
                        Color.dawnlyOrange
                    )
                }
            }
        }
    }
}

// MARK: - Data Settings

private struct DataSettingsView: View {

    let modelContext: ModelContext

    @Binding var showingClearHistoryAlert: Bool

    @State private var sessionCount = 0
    @State private var totalFocusTime:
        TimeInterval = 0

    var body: some View {

        List {

            Section {

                HStack {

                    Text("Completed sessions")

                    Spacer()

                    Text(
                        "\(sessionCount)"
                    )
                    .foregroundStyle(
                        .secondary
                    )
                    .monospacedDigit()
                }

                HStack {

                    Text("Total focus time")

                    Spacer()

                    Text(
                        formattedTotalTime
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }

            } header: {

                Text("Statistics")
            }

            Section {

                Button(role: .destructive) {

                    showingClearHistoryAlert =
                        true

                } label: {

                    HStack {

                        Image(
                            systemName:
                                "trash.fill"
                        )

                        Text("Clear history")
                    }
                }

            } footer: {

                Text(
                    "This permanently deletes all completed focus sessions."
                )
            }
        }
        .navigationTitle("Data")
        .navigationBarTitleDisplayMode(
            .inline
        )
        .task {

            loadStatistics()
        }
        .alert(
            "Clear History?",
            isPresented:
                $showingClearHistoryAlert
        ) {

            Button(
                "Cancel",
                role: .cancel
            ) { }

            Button(
                "Delete Everything",
                role: .destructive
            ) {

                clearHistory()
            }

        } message: {

            Text(
                "All completed focus sessions will be permanently deleted."
            )
        }
    }

    // MARK: Statistics

    private func loadStatistics() {

        let descriptor =
            FetchDescriptor<FocusSession>()

        do {

            let sessions =
                try modelContext.fetch(
                    descriptor
                )

            let completed =
                sessions.filter {
                    $0.completed
                }

            sessionCount =
                completed.count

            totalFocusTime =
                completed.reduce(0) {
                    $0 + $1.duration
                }

        } catch {

            print(
                "Dawnly: Failed to load statistics: \(error)"
            )
        }
    }

    // MARK: Clear History

    private func clearHistory() {

        let descriptor =
            FetchDescriptor<FocusSession>()

        do {

            let sessions =
                try modelContext.fetch(
                    descriptor
                )

            for session in sessions {

                modelContext.delete(
                    session
                )
            }

            try modelContext.save()

            sessionCount = 0
            totalFocusTime = 0

            WidgetCenter.shared
                .reloadTimelines(
                    ofKind: "DawnlyWidget"
                )

        } catch {

            print(
                "Dawnly: Failed to clear history: \(error)"
            )
        }
    }

    // MARK: Formatting

    private var formattedTotalTime: String {

        let totalMinutes =
            Int(
                totalFocusTime / 60
            )

        let hours =
            totalMinutes / 60

        let minutes =
            totalMinutes % 60

        if hours > 0 {

            if minutes == 0 {
                return "\(hours)h"
            }

            return "\(hours)h \(minutes)m"
        }

        return "\(minutes)m"
    }
}

// MARK: - Preview

#Preview {

    SettingsView()
        .modelContainer(
            for: FocusSession.self
        )
}
