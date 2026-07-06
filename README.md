# macOS Audio Input Fixer

Fixes the macOS issue where connecting AirPods (or any Bluetooth/USB audio device) automatically switches the default microphone away from the built-in MacBook mic.

Runs silently in the background as a launchd agent and instantly reverts any audio input change back to the built-in microphone.

## The Problem

Every time AirPods connect to a Mac, macOS automatically sets them as the default audio input device. This breaks:

- Meeting apps (Zoom, Google Meet, Teams) that inherit the system default
- DAWs and recording software
- Voice memos and dictation
- Any app that picks up the system microphone at session start

## How It Works

A small Swift daemon listens for `kAudioHardwarePropertyDefaultInputDevice` changes via the Core Audio API. The moment macOS switches the input to a non-built-in device, the daemon reverts it back — no polling, purely event-driven.

## Requirements

- macOS 12 Monterey or later
- Xcode Command Line Tools (`xcode-select --install`)

## Install

```bash
git clone git@github.com:eadm/macos-audio-input-fixer.git
cd macos-audio-input-fixer
./install.sh
```

The script compiles the binary, installs it to `~/.local/bin/`, and registers a LaunchAgent so it starts automatically on every login.

Logs are written to `~/Library/Logs/AudioInputFixer.log`.

## Uninstall

```bash
./uninstall.sh
```

## Related searches

- Mac microphone keeps switching to AirPods
- macOS default audio input changes automatically when AirPods connect
- Prevent AirPods from changing microphone on Mac
- Keep built-in microphone as default on macOS
- Stop Mac from switching audio input to Bluetooth headphones
- macOS audio input device keeps changing
