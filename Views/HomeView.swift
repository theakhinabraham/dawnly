import WidgetKit
import SwiftUI
import SwiftData

struct HomeView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var timerManager = TimerManager()
    @State private var customMinutes = 25

    var body: some View {

        VStack(spacing: 0) {

            // MARK: - Header

            VStack(spacing: 8) {

                Text("Dawnly")
                    .font(.largeTitle.bold())

                Text("Take a moment to focus.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // MARK: - Duration Selection

            if !timerManager.isRunning {

                VStack(spacing: 20) {

                    Text("Focus duration")
                        .font(.headline)

                    HStack(spacing: 10) {

                        PresetButton(
                            title: "25 min",
                            isSelected: timerManager.selectedPreset == .twentyFive
                        ) {
                            timerManager.selectedPreset = .twentyFive
                            timerManager.selectedDuration = 25 * 60
                        }

                        PresetButton(
                            title: "50 min",
                            isSelected: timerManager.selectedPreset == .fifty
                        ) {
                            timerManager.selectedPreset = .fifty
                            timerManager.selectedDuration = 50 * 60
                        }

                        PresetButton(
                            title: "Custom",
                            isSelected: timerManager.selectedPreset == .custom
                        ) {
                            timerManager.selectedPreset = .custom
                            timerManager.selectedDuration =
                                Double(customMinutes * 60)
                        }
                    }

                    if timerManager.selectedPreset == .custom {

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
                        .padding(.horizontal, 8)
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            // MARK: - Timer

            ZStack {

                Circle()
                    .stroke(
                        .gray.opacity(0.15),
                        lineWidth: 14
                    )

                Circle()
                    .trim(
                        from: 0,
                        to: timerManager.progress
                    )
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(
                            lineWidth: 14,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(
                        .linear(duration: 1),
                        value: timerManager.progress
                    )

                VStack(spacing: 6) {

                    Text(timerManager.formattedTime)
                        .font(
                            .system(
                                size: 48,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .monospacedDigit()

                    if timerManager.isRunning {

                        Text("Stay focused")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 260, height: 260)

            Spacer()

            // MARK: - Action

            Button {

                if timerManager.isRunning {

                    timerManager.cancel()

                    NotificationManager.shared
                        .cancelSessionCompletion()

                } else {

                    let endDate = timerManager.start()

                    NotificationManager.shared
                        .scheduleSessionCompletion(
                            at: endDate
                        )
                }

            } label: {

                Text(
                    timerManager.isRunning
                    ? "Cancel"
                    : "Start Focus"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)

            Spacer()
                .frame(height: 24)
        }
        .padding(.top, 24)
        .padding(.horizontal, 16)
        .onAppear {
            timerManager.onSessionCompleted = { session in

                modelContext.insert(session)

                do {
                    try modelContext.save()
                } catch {
                    print("Failed to save session: \(error)")
                }

                NotificationManager.shared
                    .cancelSessionCompletion()

                WidgetCenter.shared.reloadTimelines(
                    ofKind: "DawnlyWidget"
                )
            }
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
