# Security Camera App – Full Build Specification

## High-level Product Spec

- **Platforms**: Native iOS + macOS (Swift/SwiftUI, shared core)
- **Goal**: Universal IP cam client that works with cheap LookCam-style Wi-Fi cams and higher-end RTSP/ONVIF cameras, with a clean Apple-centric UX
- **Key Value**: One app where you can add almost any cam (UID/P2P or RTSP/ONVIF), view on phone and Mac, and get smart notifications, with solid privacy controls

---

## Core Features (v1)

### Live View
- Low-latency streaming, single-camera and grid view (Mac), PiP on iOS
- Basic controls: full-screen, mute/unmute, zoom, rotate

### Recording & Playback
- Motion-based and manual recording to local storage (Mac, and optionally iOS)
- Simple event list per camera with timestamps and quick scrub

### Alerts
- Motion alerts with snapshot preview, tap to jump to live view
- Per-camera notification toggles and quiet hours

### Privacy & Security
- Local-only mode (no external cloud relays except vendor P2P when required)
- Encryption in transit, Face ID/Touch ID lock, basic role separation (owner vs viewer later)

---

## Camera Compatibility Architecture

### Abstraction
- `Camera` model with `CameraKind` (`rtsp`, `onvif`, `p2p`) and properties for host/port, RTSP URL, or UID/password
- `CameraSource` protocol with `connect`, `disconnect`, `startStream`, `stopStream`, `snapshot`, plus `capabilities`
- Concrete sources: `RTSPCameraSource`, `ONVIFCameraSource`, `P2PCameraSource` (LookCam/cheap P2P)

### Camera Add Flow
- **Option 1**: Auto-discover (ONVIF scan on LAN, propose known cams)
- **Option 2**: Add by IP/URL (RTSP/HTTP, advanced)
- **Option 3**: Add by Device ID/UID (LookCam-style P2P)
- Test screen shows a preview; on success, save camera with resolved URL/capabilities

### P2P/LookCam Handling
- `P2PCameraSource` takes UID + password + region; connects via vendor-style P2P handshake and outputs a decoded stream to your player
- Advanced "RTSP probe" mode for these cams to find hidden RTSP endpoints and convert them to `rtsp` kind when possible

---

## Apple-specific Behavior

### Shared Config via iCloud
- Cameras, groups, and basic preferences sync between Mac and iPhone

### iOS
- Fast open from notifications, lock-screen/notification previews, PiP, background audio

### macOS
- Multi-camera grid, multiple windows or Spaces, menu-bar mini viewer option, background recording

---

## Data Model Sketch (Swift)

- `CameraKind`, `CameraID`, `Camera`, `CameraCapabilities` (OptionSet) as previously outlined
- Factory `CameraSourceFactory.makeSource(for:)` returns the appropriate backend instance
- Persistence via `Codable` + iCloud/CloudKit (or simple iCloud Drive JSON for v1)

---

## Conversation Summary

### Goal
Design a Mac + iPhone security camera app that works with both cheap Wi-Fi cams (like those that currently only work with the LookCam app) and more expensive, standards-compliant IP cameras. Prioritize wide compatibility, strong Apple-ecosystem UX, and privacy/security.

### Must-have Features

#### Core
- Fast live view, multi-camera dashboards (especially on Mac)
- 1080p+ video with night vision and adaptive bitrate

#### Recording
- Motion-based and manual recording
- Event clips with pre/post roll
- Scrubbable timelines
- Local + optional cloud/NAS

#### Notifications
- Real-time motion/person alerts with snapshots
- Per-camera rules, do-not-disturb, and quick mute

#### Privacy/Security
- Encryption in transit
- Local-only mode
- Clear retention controls
- Biometric lock
- Good consent/Privacy Policy messaging

#### Ecosystem
- Native iOS/macOS UI
- Shared config via iCloud
- Potential HomeKit/HSV integration for compatible cams
- Automation hooks

### Camera Compatibility Strategy
- Treat the app as a universal IP camera client with pluggable backends
- Use open standards where possible: RTSP and ONVIF for mainstream and higher-end cameras
- Add a P2P backend for cheap "LookCam-type" Wi-Fi cameras that use device IDs and vendor cloud relays

### Architecture

#### Camera Model
Define a `Camera` model with fields for:
- ID, name
- `CameraKind` (`rtsp`, `onvif`, `p2p`)
- Host/port, credentials
- Optional UID
- Derived RTSP/snapshot URLs
- Capability flags and user prefs

#### CameraSource Protocol
Create a `CameraSource` protocol exposing:
- `connect`, `disconnect`
- `startStream`, `stopStream`
- `snapshot`
- `capabilities` property

#### Concrete Implementations
- `RTSPCameraSource`
- `ONVIFCameraSource`
- `P2PCameraSource` for LookCam-style devices

#### Factory Pattern
- Use a `CameraSourceFactory` to hide backend selection from the UI

### Add-camera UX

Offer three main paths:

1. **Auto-discover**: ONVIF/RTSP scan on local network
2. **Add by IP/URL**: Manual RTSP/HTTP, advanced
3. **Add by Device ID/UID**: For LookCam/cheap P2P cams

Include a test/preview step that validates connection and infers capabilities before saving.

Provide "RTSP probe" tools for cheap cams to discover hidden RTSP URLs and then treat them as standard RTSP sources.

### Platform Behavior

#### iOS
- Focus on quick access, notifications, PiP, and simple clip management

#### macOS
- Focus on multi-camera monitoring, background recording, stronger layout tools, and diagnostics (bitrate, latency, logs)

---

## Next Steps

1. Flesh out the Swift data structures in a shared module
2. Implement at least `RTSPCameraSource` first
3. Layer in P2P support for the existing LookCam device
4. Iterate on SwiftUI "Add Camera" and live-view screens using mock sources before wiring in real networking/FFmpeg/VideoToolbox

---

## Technical Implementation Notes

### Suggested Project Structure

```
SecurityCameraApp/
├── Shared/
│   ├── Models/
│   │   ├── Camera.swift
│   │   ├── CameraKind.swift
│   │   ├── CameraCapabilities.swift
│   │   └── Recording.swift
│   ├── Services/
│   │   ├── CameraSource.swift (protocol)
│   │   ├── CameraSourceFactory.swift
│   │   ├── RTSPCameraSource.swift
│   │   ├── ONVIFCameraSource.swift
│   │   └── P2PCameraSource.swift
│   ├── Networking/
│   │   ├── RTSPClient.swift
│   │   ├── ONVIFClient.swift
│   │   └── P2PClient.swift
│   └── Utilities/
│       ├── VideoDecoder.swift
│       └── NetworkScanner.swift
├── iOS/
│   ├── Views/
│   ├── ViewModels/
│   └── App/
├── macOS/
│   ├── Views/
│   ├── ViewModels/
│   └── App/
└── Tests/
```

### Key Dependencies
- FFmpeg or VideoToolbox for video decoding
- Network framework for discovery
- CloudKit for iCloud sync
- UserNotifications for alerts

### Privacy Considerations
- Request camera/microphone permissions appropriately
- Implement App Transport Security exceptions for HTTP cameras (with user consent)
- Clear data retention policies
- Option to disable cloud features entirely
