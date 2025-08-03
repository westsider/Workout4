# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Workout4 is an iOS fitness tracking app built with SwiftUI and SwiftData. The app allows users to track their workouts, view exercise history, and manage different training routines.

## Architecture

### Core Technologies
- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Apple's new persistence framework for data modeling
- **HealthKit**: Integration prepared but currently commented out (SaveHealthkit.swift:10-44)

### Data Models
- **Exercise** (Exercise.swift:13-36): Core model representing individual exercises with properties for sets, reps, weight, completion status
- **WorkoutHistory** (Exercise.swift:39-52): Tracks completed workouts with timestamps and duration
- **ExerciseJSON/Routine** (Routine.swift): Handles JSON parsing for initial data loading

### View Architecture
- **ContentView** (ContentView.swift): Main entry point with TabView navigation
- **TrainingPlanView** (TrainingPlanView.swift): Displays workout groups with custom sorting (Stretch and Calisthenics at end)
- **WorkoutDetailView** (WorkoutDetailView.swift): Shows exercises for a specific group, handles timer and completion tracking
- **HistoryView** (HistoryView.swift): Displays completed workouts sorted by date (newest first)
- **GymMembershipView**: Membership management view

### Key Features
- Loads initial exercise data from `exercise.json` on first launch
- Tracks workout completion with automatic timer
- Persists last completed workout group in UserDefaults
- Adds 4-minute stretch time to all non-stretch workouts when recording history
- Custom workout group images displayed in the training plan

## Build and Run Commands

### Building the Project
```bash
# Build for iOS Simulator
xcodebuild -project Workout4.xcodeproj -scheme Workout4 -sdk iphonesimulator build

# Build for iOS Device
xcodebuild -project Workout4.xcodeproj -scheme Workout4 -sdk iphoneos build

# Clean build folder
xcodebuild -project Workout4.xcodeproj -scheme Workout4 clean
```

### Running Tests
```bash
# Run unit tests
xcodebuild test -project Workout4.xcodeproj -scheme Workout4 -destination 'platform=iOS Simulator,name=iPhone 15'
```

### SwiftLint (if installed)
```bash
# Run SwiftLint
swiftlint

# Auto-correct issues
swiftlint --fix
```

## Development Notes

### Data Flow
1. Initial data loads from `exercise.json` via `loadExercises()` function
2. Exercises are grouped by their `group` property for display
3. Completion status resets when leaving WorkoutDetailView to allow repeated workouts
4. History records include actual elapsed time plus 4 minutes for stretch (except stretch group itself)

### Image Assets
Workout group images are stored in Assets.xcassets with matching names:
- Falcon, Deep Horizon, Challenger, Trident, stretch, Calisthenics

### Entitlements
- App Sandbox enabled
- Read-only file access for user-selected files