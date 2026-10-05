# SolX — Golden-Hour Photography Companion ☀️📸

> **Native iOS 17+, iPadOS 17+, WidgetKit & watchOS 10+ Application**  
> Architected and engineered to the exact design and technical specifications from [midlaj.online/#projects](https://www.midlaj.online/#projects).

---

## 🌟 Overview

**SolX** is a high-precision astronomical companion engineered specifically for outdoor landscape photographers, cinematographers, and visual artists. Natural golden hour lighting lasts only a fleeting 15–25 minutes each morning and evening. SolX eliminates the guesswork by computing exact solar ephemeris angles, sun azimuth compass trajectories, and down-to-the-second countdowns to peak lighting directly on-device.

### 🎯 Key Highlights
- **Exact Portfolio Visual Replication**: Faithfully matches the interface layout, frosted glass cards, and glowing solar dials from the official SolX showcase mockup (`solx_preview.jpg`).
- **±0.01° Solar Ephemeris Engine**: Rigorous spherical trigonometry based on NOAA solar position algorithms, operating 100% offline with zero cloud dependency for remote expeditions.
- **Theme Switcher**: Complete support for both **Liquid Dark Glass** (ambient sunset atmosphere) and **Crystal Light Glass** (high-contrast daylight mode) with a toggle switch.
- **WidgetKit Extension**: Real-time relative countdown widgets for iOS and iPadOS Home Screens and Lock Screens (`systemSmall`, `systemMedium`, `systemLarge`, `accessoryCircular`, `accessoryRectangular`, `accessoryInline`).
- **Apple Watch Companion**: Lightweight, glanceable wrist companion featuring a prominent Next Golden Hour countdown, circular solar elevation gauge, azimuth bearing, and Digital Crown daylight time scrubbing.
- **Interactive Live Preview Companion**: Full standalone multi-device simulator in `preview/` enabling immediate testing and demonstration in any browser.

---

## 📱 Interface Architecture

### 1. Viewfinder & Live Camera Canvas
- **AVFoundation Live Camera Feed**: Integrates `AVCaptureSession` with auto-focus, torch control, and shutter capture on physical devices.
- **High-Definition Coastal Viewfinder Fallback**: Displays the scenic sunset backdrop in Simulator and fallback environments.
- **Composition Overlays**: Rule of Thirds, Golden Ratio (Phi grid), Center Target crosshairs, and Off.

### 2. Floating Sun Angle Compass Card
- **Frosted Glass Panel**: Translucent `.ultraThinMaterial` with specular rim lighting and soft ambient drop shadow.
- **Circular Compass Dial**: Cardinal directions (`N`, `E`, `S`, `W`) oriented to True North via `CoreLocation` compass heading (`CLHeading`).
- **Golden Sun Orbit Arc**: Visual trajectory representing the daytime sun transit across the sky dome.
- **Dynamic Azimuth Beacon**: Glowing solar pin indicator positioned at the exact real-time azimuth angle (e.g., `⊙ W 274° W`).
- **Telemetry Readout**:
  - `Sun: 274° W, Alt: +4°`
  - `Sunset: 18:49`
  - `Sunrise: 06:14`
  - `Next: Golden Hour (5m)` (live countdown)

### 3. Floating Ephemeris Timeline Card
- **Time-Travel Scrubbing Slider**: Smoothly scrub forward and backward through the 24-hour day to preview solar lighting angles in advance.
- **Glowing Solar Thumb**: Radial gradient sun indicator that glides along the daylight rail.
- **Segmented Lighting Spectrum Bar**:
  - 🟡 **Afternoon**: Warm amber daylight transition.
  - 🟠 **Golden Hour**: Peak golden illumination (-4° to +6° solar altitude).
  - 🔵 **Blue Hour**: Rich sapphire twilight (-6° to -4° solar altitude).
  - 🟣 **Night**: Deep astronomical night (< -6° altitude).
- **4-Column Ephemeris Phase Schedule**:
  - `Afternoon`: `17:30`
  - `Golden Hour`: `18:35–18:49` *(highlighted in solar gold)*
  - `Blue Hour`: `18:55–19:15` *(highlighted in sapphire blue)*
  - `Night`: `20:00`

### 4. Bottom Camera Controls Toolbar
- **Grid Toggle**: Cycles through composition framing grids with tactile haptics.
- **Torch Toggle**: Activates device flashlight for dark setup environments.
- **Tactile Shutter Button**: White inner core with outer ring, triggering screen flash and photo capture.
- **Solar Trajectory Map**: Opens full sky dome trajectory modal.
- **Settings & Theme Dial**: Opens theme switcher and GPS location presets.

---

## 🎛️ WidgetKit Architecture (`SolXWidget`)

The widget extension runs on iOS 17+ and iPadOS 17+ using Apple's `TimelineProvider` protocol. Timelines are computed locally with reload budgets aligned with astronomical milestones:

| Widget Family | Purpose | Displayed Information |
|---|---|---|
| **`systemSmall`** | Glanceable Home Screen Card | Live relative countdown to next Golden Hour, Sun altitude (`+4°`), and time window (`18:35–18:49`). |
| **`systemMedium`** | Two-Column Status Bar | Left: Prominent countdown & start time. Right: Sun bearing, elevation, sunset time, and mini lighting bar. |
| **`systemLarge`** | Comprehensive Dashboard | Full 4-phase schedule, large countdown banner, solar elevation, and azimuth bearing. |
| **`accessoryCircular`** | Lock Screen & StandBy | Circular solar icon with dynamic minutes countdown. |
| **`accessoryRectangular`** | Lock Screen Modular | `SolX Golden Hour`, live ticking countdown, window, and altitude. |
| **`accessoryInline`** | Lock Screen Top Bar | `☀️ Golden Hour in 48m` |

---

## ⌚ Apple Watch Architecture (`SolXWatch`)

Designed according to watchOS 10 design guidelines with large typography and minimal cognitive load:

1. **Next Golden Hour Countdown**: Prominently centered countdown timer (`48m 15s`).
2. **Circular Solar Elevation Gauge**: Ring progress arc tracking solar elevation from -15° horizon up to +75° zenith.
3. **Wrist Telemetry Strip**:
   - Compass bearing from North (`274° W`).
   - Sunset time (`18:49`).
4. **Digital Crown Time Travel**:
   - Rotate the Apple Watch Digital Crown to preview upcoming lighting conditions for any hour of the day.
   - Features haptic detents (`WKInterfaceDevice.play(.click)`).
   - Tap "NOW" to instantly snap back to the live minute.
5. **Watch Face Complications**: Complications for Modular, Corner, Circular, and Inline watch faces.

---

## 📐 Astronomical Math & NOAA Solar Algorithm

The core ephemeris engine in `Shared/SolarMath.swift` executes purely on-device without internet access:

1. **Fractional Year ($\gamma$)**:
   $$\gamma = \frac{2\pi}{365} \left( \text{DayOfYear} - 1 + \frac{\text{Hour} - 12}{24} \right)$$
2. **Equation of Time ($\text{EqTime}$)** in minutes:
   $$\text{EqTime} = 229.18 \times (0.000075 + 0.001868\cos\gamma - 0.032077\sin\gamma - 0.014615\cos 2\gamma - 0.040849\sin 2\gamma)$$
3. **Solar Declination ($\delta$)**:
   $$\delta = 0.006918 - 0.399912\cos\gamma + 0.070257\sin\gamma - 0.006758\cos 2\gamma + \dots$$
4. **True Solar Time ($\text{TST}$)** and **Solar Hour Angle ($\omega$)**:
   $$\text{TST} = (\text{Hour} \times 60) + \text{EqTime} + (4 \times \text{Longitude}) - (60 \times \text{TimeZoneOffset})$$
   $$\omega = \left(\frac{\text{TST}}{4}\right) - 180^\circ$$
5. **Solar Altitude ($\alpha$) and Azimuth ($A$)**:
   $$\sin\alpha = \sin\phi\sin\delta + \cos\phi\cos\delta\cos\omega$$
   $$\cos A = \frac{\sin\phi\sin\alpha - \sin\delta}{\cos\phi\cos\alpha}$$
6. **Golden Hour Boundaries**: Defined when $-4.0^\circ \le \alpha \le +6.0^\circ$.
7. **Blue Hour Boundaries**: Defined when $-6.0^\circ \le \alpha < -4.0^\circ$.

---

## 📂 Project Structure

```
SolX/
├── SolX.xcodeproj/
│   └── project.pbxproj              # Xcode project linking iOS, Widget, & Watch targets
├── Shared/
│   ├── SolarModels.swift            # SolarSnapshot, SolarPhase, EphemerisItem data types
│   ├── SolarMath.swift              # Pure Swift NOAA solar position calculator (±0.01°)
│   └── HapticService.swift          # Cross-platform tactile feedback engine
├── SolX/                            # iOS & iPadOS App Target
│   ├── Info.plist                   # Camera & Location privacy permissions
│   ├── App/
│   │   └── SolXApp.swift            # App entry point with size-class adaptation
│   ├── Core/
│   │   ├── SolarEphemerisEngine.swift # Live 1s timer & timeline scrubbing coordinator
│   │   ├── LocationManager.swift    # CoreLocation GPS, heading & photography presets
│   │   ├── CameraService.swift      # AVFoundation capture session & torch controls
│   │   └── ThemeManager.swift       # Dark & Light liquid glass styling tokens
│   ├── Views/
│   │   ├── MainCameraView.swift     # Primary screen matching solx_preview.jpg
│   │   ├── SunAngleCompassCard.swift# Floating frosted glass compass dial
│   │   ├── EphemerisTimelineCard.swift # Floating time slider & 4-column schedule
│   │   ├── CameraControlsToolbar.swift # Bottom floating dock with shutter & grid
│   │   ├── CameraViewfinderRepresentable.swift # AVFoundation preview & wallpaper fallback
│   │   ├── CompositionGridView.swift # Rule of Thirds & Golden Ratio overlays
│   │   ├── SolarTrajectoryMapView.swift # Sky dome trajectory arc modal
│   │   ├── SettingsSheetView.swift  # Theme switch toggle & location selector
│   │   └── iPadLayoutView.swift     # Adaptive dual-column iPadOS console
│   └── Assets.xcassets/
│       ├── AppIcon.appiconset/      # Full app icon suite generated from SolX.png
│       ├── AccentColor.colorset/    # Solar Gold (#F8B426)
│       └── CoastalWallpaper.imageset/# Coastal sunset wallpaper
├── SolXWidget/                      # WidgetKit Target (iOS & iPadOS)
│   ├── Info.plist                   # Widget extension descriptor
│   ├── SolXWidgetBundle.swift       # WidgetBundle entry
│   ├── SolXCountdownWidget.swift    # TimelineProvider & widget configuration
│   └── WidgetViews.swift            # Small, Medium, Large & Lock Screen widgets
├── SolXWatch/                       # Apple Watch Target (watchOS 10+)
│   ├── Info.plist                   # WatchKit application descriptor
│   ├── SolXWatchApp.swift           # watchOS App entry
│   ├── WatchMainView.swift          # Glanceable countdown, elevation gauge & crown scrub
│   ├── WatchComplications.swift     # Modular, Corner, Circular & Inline complications
│   └── Assets.xcassets/             # Watch AppIcon catalog
├── preview/                         # Interactive Multi-Device Live Preview Simulator
│   ├── index.html                   # Simulator web application
│   ├── style.css                    # Apple Liquid Glass CSS styling & themes
│   ├── solar-engine.js              # NOAA solar calculation engine (JavaScript twin)
│   ├── app.js                       # Interactive device switcher, dials & webcam logic
│   └── assets/                      # High-res icons and coastal background
└── README.md                        # Project documentation
```

---

## 🚀 Building & Running

### Prerequisites
- **macOS Sonoma** or **macOS Sequoia**
- **Xcode 15.0+** or **Xcode 16.0+**
- Active Apple Developer account (or Personal Team for on-device testing)

### Opening in Xcode
1. Open the project in Xcode:
   ```bash
   open SolX.xcodeproj
   ```
2. Select your desired active scheme:
   - `SolX` → Runs on iPhone 16 Pro, iPhone 15, or iPad Pro Simulator / Device.
   - `SolXWidget` → Tests Home Screen and Lock Screen widgets.
   - `SolXWatch` → Runs on Apple Watch Ultra 2 or Series 9/10 Simulator / Device.
3. Under **Signing & Capabilities**, select your Team.
4. Press **⌘R** to build and run!

### Running the Interactive Web Preview Simulator
You can also preview and test the complete UI immediately in any web browser without Xcode:
```bash
# Start local preview server (port 8089)
python3 -m http.server 8089 --directory preview
```
Then open:
👉 **[http://localhost:8089](http://localhost:8089)**

---

## 🎨 Theme Toggle Switch

SolX includes full support for switching between:
- **Liquid Dark Mode** (default): Sleek dark glass, amber glow highlights, specular rim reflections, and deep contrast designed for low-light evening shoots.
- **Crystal Light Mode**: Crisp frosted white glass, high-legibility dark typography, vibrant solar amber, and sapphire accents for high-glare midday sunlight.

The theme toggle is available:
1. Directly in the viewfinder header pill button.
2. Inside the Settings modal via the Apple iOS toggle switch.
3. Across all devices and in the live web simulator.

---

## 📄 License
Crafted with precision by **Muhammed Midlaj K** ([midlaj.online](https://www.midlaj.online)).
All rights reserved.
