# Design Doc: Renaming ScreenDetector to Stride

**Date:** 2026-02-12
**Status:** Completed

## Goal
Rename the project from `ScreenDetector` to `Stride` to better reflect an action-oriented, powerful, and progress-focused productivity suite.

## Brand & UI Updates
- **Display Name:** Change all user-facing instances of "Screen Detector" or "ScreenDetector" to "Stride".
- **Visuals:** Ensure the "Warm Paper" aesthetic remains consistent with the new energetic name.
- **Documentation:** Update `README.md` and `COLORS.md`.

## Filesystem & Project Structure
- **Swift Package:** Rename the package and the main target in `Package.swift` from `ScreenDetector` to `Stride`.
- **Directory Structure:**
    - Rename `Sources/ScreenDetector` to `Sources/Stride`.
- **Build Artifacts:** Update scheme names and product names in the build configuration.

## Internal Code Refactoring
- **Main App Entry:** Rename `ScreenDetectorApp.swift` to `StrideApp.swift` and the struct `ScreenDetectorApp` to `StrideApp`.
- **Symbols:** Perform a targeted search and replace for `ScreenDetector` to `Stride` in class names, variable names, and comments where appropriate.
- **Bundle Identifier:** Update the bundle identifier if necessary (e.g., `com.user.ScreenDetector` to `com.user.Stride`). *Note: This may affect local storage paths if they are tied to the bundle ID.*

## Verification Plan
1. **Build:** Verify the project compiles successfully using `swift build`.
2. **Execution:** Run the app to ensure the UI displays "Stride" correctly.
3. **Data Integrity:** Check that existing databases (Habit, Weekly Log) are still loading correctly.
4. **Tests:** Run all unit tests to ensure no logic was broken by the renaming.
