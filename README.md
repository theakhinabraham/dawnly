# 🌅 Dawnly

> A mindful Pomodoro and focus timer for iPhone, built with SwiftUI, SwiftData, WidgetKit, and ActivityKit.

Dawnly is a minimal productivity app designed to help you focus on what matters without adding unnecessary complexity.

It combines a clean Pomodoro timer with focus-session tracking, Home Screen widgets, and Live Activities so your current session stays visible when you need it.

---

## ✨ Features

- ⏱️ **Pomodoro Focus Timer**
  - 25-minute focus sessions
  - 50-minute focus sessions
  - Custom session durations
  - Real-time countdown
  - Start, finish, and cancel sessions

- 📊 **Focus Tracking**
  - Automatically records completed focus sessions
  - Tracks total focus time
  - Displays today's focus time
  - Persistent session history using SwiftData

- 📱 **Home Screen Widget**
  - Shows today's total focus time
  - Minimal Dawnly interface
  - Small and medium widget support
  - Refreshes when focus data changes

- 🔴 **Live Activities**
  - Shows an active Pomodoro session on the Lock Screen
  - Live countdown timer
  - Focus status
  - Dynamic Island support
  - Compact, expanded, and minimal presentations

- 🔔 **Notifications**
  - Notifies you when a focus session is completed
  - Cancels the scheduled notification when a session is cancelled

- 🎨 **Minimal UI**
  - Clean SwiftUI interface
  - Focus-oriented design
  - Responsive layouts
  - Native iOS components

---

## 🛠️ Tech Stack

| Technology | Purpose |
|---|---|
| Swift | Primary programming language |
| SwiftUI | User interface |
| SwiftData | Persistent data storage |
| WidgetKit | Home Screen widgets |
| ActivityKit | Live Activities and Dynamic Island |
| Observation | Observable application state |
| UserNotifications | Focus completion notifications |
| Xcode | Development environment |

---

## 🏗️ Architecture

Dawnly uses a native Apple-platform architecture centered around SwiftUI.

```text
Dawnly
│
├── SwiftUI
│   ├── Timer Screen
│   ├── Focus UI
│   └── Supporting Views
│
├── TimerManager
│   ├── Timer state
│   ├── Countdown
│   ├── Session lifecycle
│   └── Live Activity management
│
├── SwiftData
│   ├── FocusSession
│   ├── Session persistence
│   └── Focus history
│
├── WidgetKit
│   ├── Home Screen Widget
│   ├── Today's focus
│   └── Shared session state
│
├── ActivityKit
│   ├── Live Activity
│   ├── Lock Screen countdown
│   └── Dynamic Island
│
└── UserNotifications
    └── Session completion notification
```

---

## 📁 Project Structure

The project is organized approximately like this:

```text
Dawnly/
│
├── Dawnly/
│   ├── DawnlyApp.swift
│   ├── TimerManager.swift
│   ├── FocusSession.swift
│   ├── SharedModelContainer.swift
│   ├── DawnlySharedState.swift
│   ├── NotificationManager.swift
│   │
│   ├── Views/
│   │   ├── ContentView.swift
│   │   └── ...
│   │
│   └── Assets.xcassets
│
├── DawnlyWidget/
│   ├── DawnlyWidget.swift
│   ├── DawnlyActivityAttributes.swift
│   ├── DawnlyWidgetBundle.swift
│   └── ...
│
├── Dawnly.xcodeproj
│
└── README.md
```

---

## ⏱️ How the Timer Works

When a focus session starts, Dawnly:

1. Creates a start date.
2. Calculates the end date.
3. Updates the local timer state.
4. Saves the active session state for the widget.
5. Starts a Live Activity.
6. Starts the local countdown timer.
7. Schedules a completion notification.

The timer uses the calculated end date rather than simply subtracting one second on every timer callback.

This makes the countdown more reliable if the application is temporarily interrupted.

```swift
let now = Date()

let endDate =
    now.addingTimeInterval(duration)

startDate = now
self.endDate = endDate

timeRemaining = duration
isRunning = true
```

The remaining time is calculated using:

```swift
let remaining =
    endDate.timeIntervalSinceNow
```

---

## 🧠 Focus Sessions

Completed sessions are stored using SwiftData.

A `FocusSession` contains information such as:

```text
Start Date
End Date
Duration
Completion Status
```

This allows Dawnly to calculate daily focus statistics without relying entirely on temporary application state.

---

## 📱 Home Screen Widget

The Dawnly Home Screen widget displays the user's focus progress for the current day.

Example:

```text
┌──────────────────────────┐
│ ☀︎ Dawnly                 │
│                          │
│ Today's focus            │
│                          │
│ 1h 25m                   │
│                          │
│ Keep going          ↗    │
└──────────────────────────┘
```

The widget reads completed focus sessions from the shared SwiftData container.

When a focus session starts or ends, WidgetKit timelines are refreshed:

```swift
WidgetCenter.shared.reloadAllTimelines()
```

---

## 🔴 Live Activities

Dawnly uses ActivityKit to display active focus sessions outside the application.

The Live Activity provides:

- Current focus status
- Countdown timer
- Dawnly branding
- Lock Screen presentation
- Dynamic Island presentation

The countdown uses the session's start and end dates:

```swift
Text(
    timerInterval:
        context.state.startDate
        ...
        context.state.endDate,
    countsDown: true
)
```

This allows the system to display the countdown independently of the application's normal UI.

---

## 🏝️ Dynamic Island

On supported iPhone models, Dawnly provides three Dynamic Island presentations.

### Expanded

```text
Dawnly                 FOCUS

              24:32

Stay focused.
```

### Compact

Displays the Dawnly icon alongside the remaining time.

### Minimal

Displays a timer icon when space is limited.

---

## 🔔 Notifications

Dawnly uses Apple's UserNotifications framework to notify users when their focus session finishes.

When a session starts:

```text
Schedule notification
        ↓
Focus session
        ↓
Session completes
        ↓
Notification appears
```

When a session is cancelled, the corresponding notification is removed.

---

## 💾 Shared Data

Dawnly uses a shared App Group so the main application and widget extension can access the same information.

The App Group is:

```text
group.com.akhin.dawnly
```

The shared container allows the application and widget extension to communicate session state.

Shared state includes information such as:

```text
Active session
Start date
End date
Session status
```

---

## 🔐 App Group Configuration

The main application and widget extension should both have the same App Group capability.

In Xcode:

```text
Target
    ↓
Signing & Capabilities
    ↓
+ Capability
    ↓
App Groups
```

Add:

```text
group.com.akhin.dawnly
```

Make sure the same App Group is enabled for:

```text
Dawnly
DawnlyWidget
```

---

## 🔴 Live Activity Configuration

The widget extension must support Live Activities.

In Xcode, open the appropriate target and check:

```text
Target
    ↓
Signing & Capabilities
```

Ensure the required Live Activities / ActivityKit configuration is enabled.

The project should also use a compatible iOS deployment target for the APIs being used.

---

## 🧩 SwiftData Shared Container

Dawnly uses a shared `ModelContainer` so the application and widget can access the same SwiftData database.

The container is configured using the App Group:

```swift
let configuration = ModelConfiguration(
    schema: schema,
    groupContainer: .identifier(
        "group.com.akhin.dawnly"
    )
)
```

This allows the widget extension to read completed focus sessions.

---

## 🚀 Getting Started

### Requirements

- macOS
- Xcode
- iPhone running a compatible iOS version
- Apple Developer account for device capabilities such as App Groups and Live Activities

---

## 📥 Clone the Repository

Clone the repository using Git:

```bash
git clone https://github.com/YOUR_USERNAME/dawnly.git
```

Then move into the project:

```bash
cd dawnly
```

Open the project:

```bash
open Dawnly.xcodeproj
```

---

## 🔧 Configure Signing

After opening the project in Xcode:

```text
Dawnly
    ↓
Target
    ↓
Signing & Capabilities
```

Select your Apple Developer Team.

Repeat this for:

```text
Dawnly
DawnlyWidget
```

---

## 📱 Run on iPhone

Connect your iPhone to your Mac.

Then:

```text
Xcode
    ↓
Device Selection
    ↓
Your iPhone
    ↓
Run ▶
```

The application should build and install on the device.

---

## 🧪 Testing

### Test the Timer

1. Open Dawnly.
2. Select a focus duration.
3. Tap **Start Focus**.
4. Verify the countdown.
5. Lock the iPhone.
6. Check the Live Activity.
7. Allow the session to complete.
8. Verify the completion notification.
9. Return to the application.
10. Check today's focus time.

### Test Cancellation

1. Start a focus session.
2. Lock the device.
3. Verify the Live Activity appears.
4. Return to Dawnly.
5. Cancel the session.
6. Verify the Live Activity disappears.
7. Verify the widget updates.
8. Verify the session was not recorded as completed.

---

## 🐛 Troubleshooting

### Live Activity Does Not Appear

Check:

```text
Settings
    ↓
Apps
    ↓
Dawnly
    ↓
Live Activities
```

Make sure Live Activities are enabled.

Also verify that the widget extension has the correct configuration and deployment target.

---

### Widget Does Not Update

Try:

```text
Remove widget
    ↓
Add widget again
```

Then run the application and start or finish a session.

The application should request a widget timeline refresh:

```swift
WidgetCenter.shared.reloadAllTimelines()
```

Also verify that both targets use the same App Group:

```text
group.com.akhin.dawnly
```

---

### Widget Shows Old Data

WidgetKit controls when timeline updates occur.

For important state changes, Dawnly explicitly requests a timeline refresh.

If stale data remains during development, removing and re-adding the widget can force WidgetKit to recreate its timeline.

---

### SwiftData Errors

Verify that:

```text
Dawnly
DawnlyWidget
```

both use the same model schema and shared container configuration.

The App Group must also be correctly configured.

---

## 🧹 Clean Build

If Xcode behaves unexpectedly:

```text
Product
    ↓
Clean Build Folder
```

Then build again.

You can also delete the application from the iPhone and reinstall it.

---

## 🔄 Development Workflow

A typical development workflow is:

```text
Modify code
    ↓
Build
    ↓
Run on iPhone
    ↓
Test timer
    ↓
Test Live Activity
    ↓
Test widget
    ↓
Commit changes
    ↓
Push to GitHub
```

---

## 🌿 Git Workflow

Check your current changes:

```bash
git status
```

Add your changes:

```bash
git add .
```

Commit:

```bash
git commit -m "Update Dawnly timer and widgets"
```

Push:

```bash
git push origin main
```

---

## 🏷️ Suggested Commit Messages

Use descriptive commits such as:

```text
feat: add Pomodoro timer
feat: add SwiftData focus sessions
feat: add Home Screen widget
feat: add Live Activities
feat: add Dynamic Island support
feat: add focus completion notifications
fix: update widget after session completion
fix: stop Live Activity when session is cancelled
style: refine widget spacing and typography
```

---

## 🎨 Design Philosophy

Dawnly is designed around three principles.

### 1. Minimal

The interface should stay out of the user's way.

### 2. Calm

The application should encourage focused work rather than create additional distractions.

### 3. Useful

Every element should have a purpose.

The timer, widget, Live Activity, notifications, and focus history are designed to work together as one system.

---

## 🗺️ Roadmap

Potential future improvements include:

- [ ] Focus session history
- [ ] Weekly focus statistics
- [ ] Monthly focus statistics
- [ ] Focus streaks
- [ ] Daily focus goals
- [ ] Custom Pomodoro presets
- [ ] Short breaks
- [ ] Long breaks
- [ ] Automatic Pomodoro cycles
- [ ] Custom notification sounds
- [ ] Focus categories
- [ ] Session notes
- [ ] Calendar integration
- [ ] Charts and analytics
- [ ] iCloud synchronization
- [ ] Apple Watch support
- [ ] Mac support
- [ ] Improved widget interactions
- [ ] App Intents / Shortcuts integration
- [ ] Accessibility improvements

---

## 🔒 Privacy

Dawnly is designed to keep focus-session data on the user's device.

The application does not require an account to track local focus sessions.

Data used for focus tracking is stored locally using Apple's SwiftData framework.

---

## 📜 License

This project is currently developed as a personal project.

If a formal open-source license is added in the future, it will be documented here.

---

## 👨‍💻 Author

**Akhin Abraham**

MCA Student  
JAIN University, Kochi

BCA — Mobile Application & Cloud Technology

---

## 🌅 About Dawnly

Dawnly is built around a simple idea:

> **Start small. Focus deeply. Keep going.**

Instead of trying to optimize every minute of the day, Dawnly is designed to make starting a focused session feel simple.

One session at a time.

---

## ⭐ Support

If you find Dawnly interesting, consider giving the repository a ⭐ on GitHub.

Issues, suggestions, and contributions are welcome.

---

## 📌 Project Status

**Status:** 🚧 Active Development

Dawnly is currently under development, with new features and improvements being added regularly.
