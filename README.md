# ScoutCam

Native iOS app (iOS 26, Liquid Glass) for Mscam/Motorola Scout-style WiFi cameras:
find them on your network, watch the live feed, pan/tilt, digital zoom, hear the
camera's mic, and push-to-talk through the camera's speaker — plus a skippable
setup wizard that joins a new camera to your home Wi-Fi.

## Features
- **Home grid**: a square "+" tile first, then one square per camera found on the
  network (model name shown; tap the ✏️ pencil on the square to rename).
- **Setup wizard (skippable)**: join the camera's own Wi-Fi, come back, enter your
  home Wi-Fi, and the app provisions the camera onto your network.
- **Camera page**: feed on top, pan/tilt joystick, zoom slider under the joystick,
  back button top-left, hold-to-talk button top-right (uses your mic, streams to
  the camera speaker), live camera audio through your phone (when not on silent).
- **Theme follows your device** (system light/dark automatically).
- **Liquid Glass** buttons/cards (iOS 26).

## Building the IPA (GitHub Actions)
Push this repo to GitHub — `.github/workflows/build.yml` runs on **every push** on
`macos-latest` (newest macOS/Xcode), installs XcodeGen, generates the project,
builds with `CODE_SIGNING_ALLOWED=NO`, and packages an **unsigned `ScoutCam.ipa`**
as a workflow artifact. Download it from the Actions tab.

Locally on a Mac: `brew install xcodegen && ./build.sh`

## Installing the IPA on a device
The IPA is unsigned. Install with a side-loader such as **AltStore / Sideloadly**,
or sign it with your Apple ID in Xcode and run it on your own device.

## Notes / assumptions
- Default camera credentials are `camera:000000` (change in the Add sheet).
- Provisioning sends `setup_wireless_save&setup=<base64("ssid;password;3")>` then
  `restart_system` — best effort against this camera family.
- Zoom is digital (these cameras have no optical zoom).
- Pan/tilt mapping uses `move_forward`=tilt-up by default; if your unit is
  inverted, swap the mapping in `CameraSession.nudge`.
