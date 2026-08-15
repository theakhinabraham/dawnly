import WidgetKit
import SwiftUI
import SwiftData

struct HomeView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var timerManager = TimerManager()
    @State private var customMinutes = 25

    // MARK: - Dawnly Theme

    private let dawnlyOrange = Color(
        red: 1.0,
        green: 0.55,
        blue: 0.15
    )

    var body: some View {

        VStack(spacing: 0) {

            // MARK: - Header

            VStack(spacing: 6) {

                Text("Dawnly")
                    .font(
                        .system(
                            size: 30,
                            weight: .bold,
                            design: .rounded
                        )
                    )

                Text(
                    timerManager.isRunning
                    ? "Stay present. Stay focused."
                    : "Take a moment to focus."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .animation(
                    .easeInOut(duration: 0.2),
                    value: timerManager.isRunning
                )
            }
            .padding(.top, 8)

            Spacer()

            // MARK: - Duration Selection

            if !timerManager.isRunning {

                VStack(spacing: 18) {

                    VStack(spacing: 4) {

                        Text("Focus duration")
                            .font(
                                .system(
                                    size: 17,
                                    weight: .semibold
                                )
                            )

                        Text("Choose how long you want to focus")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 8) {

                        PresetButton(
                            title: "25 min",
                            isSelected:
                                timerManager.selectedPreset == .twentyFive
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                timerManager.selectedPreset = .twentyFive
                                timerManager.selectedDuration = 25 * 60
                            }
                        }

                        PresetButton(
                            title: "50 min",
                            isSelected:
                                timerManager.selectedPreset == .fifty
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                timerManager.selectedPreset = .fifty
                                timerManager.selectedDuration = 50 * 60
                            }
                        }

                        PresetButton(
                            title: "Custom",
                            isSelected:
                                timerManager.selectedPreset == .custom
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                timerManager.selectedPreset = .custom
                                timerManager.selectedDuration =
                                    Double(customMinutes * 60)
                            }
                        }
                    }

                    if timerManager.selectedPreset == .custom {

                        HStack(spacing: 12) {

                            Image(systemName: "clock")
                                .foregroundStyle(dawnlyOrange)

                            Stepper(
                                "\(customMinutes) minutes",
                                value: $customMinutes,
                                in: 5...180,
                                step: 5
                            )
                            .onChange(of: customMinutes) {
                                timerManager.selectedDuration =
                                    Double(customMinutes * 60)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            Color.secondary.opacity(0.07),
                            in: RoundedRectangle(
                                cornerRadius: 14
                            )
                        )
                        .transition(
                            .opacity.combined(
                                with: .move(edge: .top)
                            )
                        )
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            // MARK: - Timer

            VStack(spacing: 18) {

                if timerManager.isRunning {

                    Text("FOCUSING")
                        .font(
                            .system(
                                size: 11,
                                weight: .bold
                            )
                        )
                        .tracking(1.8)
                        .foregroundStyle(dawnlyOrange)
                        .transition(.opacity)
                } else {

                    Text("READY")
                        .font(
                            .system(
                                size: 11,
                                weight: .bold
                            )
                        )
                        .tracking(1.8)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }

                ZStack {

                    // Background ring

                    Circle()
                        .stroke(
                            Color.secondary.opacity(0.10),
                            lineWidth: 15
                        )

                    // Progress ring

                    Circle()
                        .trim(
                            from: 0,
                            to: timerManager.progress
                        )
                        .stroke(
                            dawnlyOrange,
                            style: StrokeStyle(
                                lineWidth: 15,
                                lineCap: .round
                            )
                        )
                        .rotationEffect(
                            .degrees(-90)
                        )
                        .animation(
                            .linear(duration: 1),
                            value: timerManager.progress
                        )

                    // Subtle center glow while running

                    if timerManager.isRunning {

                        Circle()
                            .fill(
                                dawnlyOrange.opacity(0.06)
                            )
                            .frame(
                                width: 190,
                                height: 190
                            )
                            .transition(.opacity)
                    }

                    VStack(spacing: 8) {

                        Text(
                            timerManager.formattedTime
                        )
                        .font(
                            .system(
                                size: 52,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .monospacedDigit()
                        .foregroundStyle(
                            timerManager.isRunning
                            ? .primary
                            : .primary
                        )
                        .contentTransition(
                            .numericText()
                        )

                        Text(
                            timerManager.isRunning
                            ? "Stay focused"
                            : "Your time"
                        )
                        .font(
                            .system(
                                size: 13,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(.secondary)
                    }
                }
                .frame(
                    width: 280,
                    height: 280
                )
                .shadow(
                    color:
                        timerManager.isRunning
                        ? dawnlyOrange.opacity(0.12)
                        : .clear,
                    radius: 20
                )
            }

            Spacer()

            // MARK: - Action

            Button {

                if timerManager.isRunning {

                    timerManager.cancel()

                    NotificationManager.shared
                        .cancelSessionCompletion()

                } else {

                    let endDate =
                        timerManager.start()

                    NotificationManager.shared
                        .scheduleSessionCompletion(
                            at: endDate
                        )
                }

            } label: {

                HStack(spacing: 8) {

                    Image(
                        systemName:
                            timerManager.isRunning
                            ? "xmark"
                            : "play.fill"
                    )
                    .font(
                        .system(
                            size: 13,
                            weight: .bold
                        )
                    )

                    Text(
                        timerManager.isRunning
                        ? "End Session"
                        : "Start Focus"
                    )
                    .font(
                        .system(
                            size: 17,
                            weight: .semibold
                        )
                    )
                }
                .frame(
                    maxWidth: .infinity
                )
                .padding(.vertical, 17)
            }
            .buttonStyle(
                .borderedProminent
            )
            .tint(
                timerManager.isRunning
                ? Color.secondary
                : dawnlyOrange
            )
            .controlSize(.large)
            .padding(.horizontal, 24)

            Spacer()
                .frame(height: 24)
        }
        .padding(.horizontal, 16)
        .animation(
            .easeInOut(duration: 0.25),
            value: timerManager.isRunning
        )
        .onAppear {

            timerManager.onSessionCompleted = { session in

                modelContext.insert(session)

                do {

                    try modelContext.save()

                    print(
                        "Dawnly: Focus session saved successfully."
                    )

                } catch {

                    print(
                        "Dawnly: Failed to save focus session: \(error)"
                    )
                }

                NotificationManager.shared
                    .cancelSessionCompletion()

                WidgetCenter.shared.reloadTimelines(
                    ofKind: "DawnlyWidget"
                )
            }

            timerManager.refresh()
        }
        .onChange(of: scenePhase) { _, newPhase in

            if newPhase == .active {
                timerManager.refresh()
            }
        }
    }
}

#Preview {
    HomeView()
}
