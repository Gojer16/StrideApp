# Implementation Plan: Rename to Stride

## Phase 1: Filesystem & Configuration
- [x] Rename `Sources/ScreenDetector` directory to `Sources/Stride`.
- [x] Rename `Sources/Stride/ScreenDetectorApp.swift` to `Sources/Stride/StrideApp.swift`.
- [x] Update `Package.swift`:
    - Rename package name to "Stride".
    - Rename library/executable targets to "Stride".
    - Update dependencies/path references.

## Phase 2: Source Code Refactoring
- [x] Rename `ScreenDetectorApp` struct to `StrideApp`.
- [x] Global search and replace (case-sensitive) `ScreenDetector` with `Stride`.
- [x] Global search and replace (case-insensitive where safe) `screen-detector` with `stride`.
- [x] Update any string literals in UI (e.g., "Live", "All Apps").

## Phase 3: Documentation & Metadata
- [x] Update `README.md` with new name and descriptions.
- [x] Update `COLORS.md` if it contains the old name.
- [x] Update `.build` folder configuration if necessary (usually handled by `swift build`).

## Phase 4: Verification
- [x] Run `swift build` to ensure project compiles.
- [x] Run `swift test` (if tests exist) to verify logic.
- [x] Manually check `StrideApp.swift` for consistency.
