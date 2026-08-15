# 🌅 Dawnly

> A simple, beautiful focus timer designed to help you slow down, focus, and get things done.

Dawnly is an iOS productivity and focus timer app built with **SwiftUI**. It combines a clean, minimal interface with native iOS features such as **Live Activities, Dynamic Island, Home Screen widgets, local notifications, and SwiftData**.

The goal of Dawnly is simple:

**Start a session. Focus on one thing. Finish it.**

---

## ✨ Features

### ⏱️ Focus Timer

- Pomodoro-style focus sessions
- 25-minute focus preset
- 50-minute focus preset
- Custom session durations
- Live countdown timer
- Session progress indicator
- Start, cancel, and finish sessions

### 📱 Live Activities

Dawnly uses Apple's ActivityKit to provide an active focus session directly on the Lock Screen.

While focusing, users can see:

- Remaining time
- Session status
- Dawnly branding
- Focus indicator

### 🏝️ Dynamic Island

On supported iPhone models, active focus sessions appear in the Dynamic Island.

The Dynamic Island provides:

- Compact countdown
- Dawnly icon
- Expanded focus session information
- Current session status

### 🧩 Home Screen Widgets

Dawnly includes Home Screen widgets that display:

- Today's total focus time
- Active focus session
- Live countdown during an active session
- Focus status

The widget automatically updates when a session starts, finishes, or is cancelled.

### 🔔 Notifications

Dawnly can notify the user when a focus session is completed.

### 📊 Focus History

Completed focus sessions are stored using Apple's SwiftData framework.

This allows Dawnly to keep track of:

- Session start time
- Session end time
- Session duration
- Completion status
- Daily focus time

---

## 🛠️ Technologies

Dawnly is built using native Apple technologies.

| Technology | Purpose |
|---|---|
| Swift | Programming language |
| SwiftUI | User interface |
| SwiftData | Persistent session storage |
| WidgetKit | Home Screen widgets |
| ActivityKit | Live Activities |
| Dynamic Island | Live focus sessions |
| UserNotifications | Session completion notifications |
| Observation | Reactive app state |
| App Groups | Shared data between app and widget |

---

## 🏗️ Architecture

Dawnly follows a lightweight SwiftUI architecture with shared state between the main application and its widget extension.

```text
Dawnly
│
├── Main App
│   ├── SwiftUI Views
│   ├── TimerManager
│   ├── NotificationManager
│   └── SwiftData
│
├── Widget Extension
│   ├── Home Screen Widget
│   └── Live Activity
│
└── Shared
    ├── FocusSession
    ├── SharedModelContainer
    └── DawnlySharedState
