import SwiftUI

struct GoalsSettingsView: View {

    @AppStorage("dailyFocusGoalMinutes")
    private var dailyFocusGoalMinutes =
        GoalSettings.defaultFocusGoalMinutes

    @AppStorage("dailySessionGoal")
    private var dailySessionGoal =
        GoalSettings.defaultSessionGoal

    private let focusGoalOptions = [
        15,
        30,
        45,
        60,
        90,
        120,
        180,
        240,
        300,
        360,
        480
    ]

    private let sessionGoalOptions = [
        1,
        2,
        3,
        4,
        5,
        6,
        8,
        10,
        12,
        15,
        20
    ]

    var body: some View {

        List {

            // =========================================================
            // MARK: Focus Goal
            // =========================================================

            Section {

                ForEach(
                    focusGoalOptions,
                    id: \.self
                ) { minutes in

                    Button {

                        dailyFocusGoalMinutes =
                            minutes

                    } label: {

                        HStack {

                            Text(
                                GoalSettings.focusGoalLabel(
                                    minutes: minutes
                                )
                            )
                            .foregroundStyle(
                                .primary
                            )

                            Spacer()

                            if dailyFocusGoalMinutes
                                == minutes {

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
                    .buttonStyle(.plain)
                }

            } header: {

                Text("Daily focus goal")

            } footer: {

                Text(
                    "Choose how much focused time you'd like to complete each day."
                )
            }

            // =========================================================
            // MARK: Session Goal
            // =========================================================

            Section {

                ForEach(
                    sessionGoalOptions,
                    id: \.self
                ) { sessions in

                    Button {

                        dailySessionGoal =
                            sessions

                    } label: {

                        HStack {

                            Text(
                                sessions == 1
                                ? "1 session"
                                : "\(sessions) sessions"
                            )
                            .foregroundStyle(
                                .primary
                            )

                            Spacer()

                            if dailySessionGoal
                                == sessions {

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
                    .buttonStyle(.plain)
                }

            } header: {

                Text("Daily session goal")

            } footer: {

                Text(
                    "Choose how many completed focus sessions you'd like to achieve each day."
                )
            }

            // =========================================================
            // MARK: Current Goals
            // =========================================================

            Section {

                HStack {

                    HStack(spacing: 10) {

                        Image(
                            systemName:
                                "clock.fill"
                        )
                        .foregroundStyle(
                            Color.dawnlyOrange
                        )

                        Text("Focus")

                    }

                    Spacer()

                    Text(
                        GoalSettings.focusGoalLabel(
                            minutes:
                                dailyFocusGoalMinutes
                        )
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }

                HStack {

                    HStack(spacing: 10) {

                        Image(
                            systemName:
                                "checkmark.circle.fill"
                        )
                        .foregroundStyle(
                            Color.dawnlyOrange
                        )

                        Text("Sessions")

                    }

                    Spacer()

                    Text(
                        dailySessionGoal == 1
                        ? "1 session"
                        : "\(dailySessionGoal) sessions"
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }

            } header: {

                Text("Your goals")
            }
        }
        .navigationTitle("Goals")
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}
