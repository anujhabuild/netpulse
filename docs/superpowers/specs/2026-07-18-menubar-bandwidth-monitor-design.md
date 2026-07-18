# Menu Bar Bandwidth Monitor — Design Spec

Date: 2026-07-18
Status: Approved

## Purpose

A lightweight native macOS menu bar app that displays real-time upload and
download network speeds, in the style of Stats / iStat Menus. Runs
persistently in the menu bar next to system icons (Wi-Fi, Bluetooth, etc.).

## Tech Stack

Swift + SwiftUI, targeting macOS 13+ (required for `SMAppService`).
No Electron/web tech — chosen for low resource usage and native menu bar
integration (drag-to-reorder behaves identically to system icons).

## Components

### 1. `NetworkMonitor`

- Polls interface byte counters via `getifaddrs()` (BSD C API, `AF_LINK`
  family, reading `if_data.ifi_ibytes` / `ifi_obytes`) once per second via a
  repeating `Timer`.
- Iterates all interfaces, filtering out loopback and interfaces that are not
  both `IFF_UP` and `IFF_RUNNING`.
- Sums received/transmitted byte deltas across **all active interfaces**
  combined (Wi-Fi + Ethernet + any other active interface) — not just the
  default route.
- Computes `uploadBytesPerSec` / `downloadBytesPerSec` as
  `(currentBytes - previousBytes) / elapsedSeconds`.
- Exposes both values as `@Published` properties on an `ObservableObject` so
  SwiftUI views update automatically via Combine.
- Tracks a running **session total** (bytes transferred since app launch) for
  display in the popover.
- On sleep/wake (`NSWorkspace` sleep/wake notifications): stops the timer on
  sleep, and on wake discards the stale previous-sample baseline (takes a
  fresh baseline sample instead of computing a delta across the sleep
  duration) to avoid one large spurious spike.
- If `getifaddrs()` returns no data on a given tick (rare/transient), the
  previous published values are held rather than showing zero or garbage;
  normal sampling resumes next tick.

### 2. Menu Bar Item

- A single `NSStatusItem` with a fixed-width monospaced-digit label showing
  both values on one line: `↑ 1.2 MB/s   ↓ 3.4 MB/s`.
- Standard `NSStatusItem` positioning — draggable/reorderable by the user via
  Cmd-drag exactly like Wi-Fi/Bluetooth icons. No app-level control over
  exact placement; this is a macOS system behavior, not something the app can
  configure. Position persists across launches (system-managed).
- Clicking the item opens the popover (see below).

### 3. Popover Panel

SwiftUI view shown when the menu bar item is clicked:

- Large current upload/download numbers (same auto-scaling formatter as the
  menu bar).
- A mini live sparkline graph plotting the last ~60 samples (60 seconds) of
  download speed (and upload, distinguished by color).
- Session total data transferred (upload + download, since app launch).
- Name(s) of currently active interface(s) (e.g. "Wi-Fi", "Wi-Fi + Ethernet").
- Footer controls:
  - **"Launch at Login" toggle** — reflects and controls current login-item
    registration state. Off by default; user opts in.
  - **Quit** button.

### 4. `LaunchAtLoginManager`

- Wraps `SMAppService.mainApp` (macOS 13+ `ServiceManagement` API).
- `isEnabled` reads current registration status.
- Toggling calls `register()` / `unregister()` and updates the popover toggle
  state accordingly, including surfacing any error (e.g. registration denied)
  back to the toggle so it doesn't show a false "on" state.
- Default state: **not registered** (manual launch) until the user
  explicitly enables it in the popover — per user preference, this is a
  user-facing choice, not a forced default.

## Data Formatting

- `ByteRateFormatter`: auto-scales `B/s` → `KB/s` → `MB/s` using 1024-based
  (binary) thresholds, matching Activity Monitor's convention.
- One decimal place once scaled above B/s (e.g. `1.2 MB/s`), no decimals for
  raw `B/s` values.
- Handles `0 B/s` explicitly (no active traffic) without special-casing
  elsewhere in the UI.

## Error Handling

- `getifaddrs()` failure or empty interface list: hold last-known displayed
  values; retry on next tick; never crash or show negative/NaN speeds.
- Sleep/wake: see `NetworkMonitor` above — baseline reset prevents a fake
  spike representing elapsed sleep time.
- Login item registration failure: reflected back in the popover toggle
  rather than silently failing.

## Testing

- **Unit tests** for `NetworkMonitor`'s delta-computation logic: feed
  sequences of mock interface byte counters (including a simulated sleep/wake
  gap) and assert correct computed speeds and correct spike suppression.
- **Unit tests** for `ByteRateFormatter`: edge cases at 0, just-under-1024,
  exactly-1024, and large (GB/s-scale, to confirm it doesn't misbehave)
  values.
- **Manual verification**: run the app during an active download/upload and
  compare displayed speeds against Activity Monitor's Network tab for
  plausibility; verify the menu bar item drags/reorders like a system icon;
  verify the Launch at Login toggle actually persists across a restart.

## Out of Scope (v1)

- Custom refresh rate / unit configuration (fixed at 1s refresh, auto-scaling
  units for now).
- Per-interface breakdown in the UI (data is summed; only the active
  interface *names* are shown, not separate speeds per interface).
- Historical/long-term usage graphs beyond the in-memory 60-second sparkline.
