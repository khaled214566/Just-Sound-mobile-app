# JUST SOUND Music Player

A Flutter-based music player and downloader app with local audio playback, playlist management, favorites, theme selection, and YouTube-to-audio download support.

## Overview

This project is a polished audio app built with Flutter, designed to discover and play local audio files, store favorite songs, manage playlists, and download YouTube videos as audio tracks.

The app includes:

- Local music discovery and playback
- Favorites management with SQLite persistence
- Playlist creation, editing, and song organization using Hive
- YouTube audio download and metadata embedding
- Mini-player controls and queue management
- Light/Dark mode selection and theme persistence
- First-launch onboarding flow

## Key Features

### Audio Playback

- Plays local audio files from device storage
- Supports MP3 and M4A files
- Displays song metadata: title, artist, album, cover artwork
- Uses `just_audio` and `just_audio_background` for smooth playback
- Handles next-track autoplay and playback state changes

### Favorites

- Mark songs as favorites from the main track list
- Favorites persist in a local SQLite database
- View and play favorites in a dedicated tab
- Remove favorites directly from the favorites screen

### Playlists

- Create, rename, and delete playlists
- Add songs to playlists from the Songs screen
- View playlist contents and play songs from a playlist
- Remove songs from a playlist without deleting the file

### Download / Converter

- Paste a YouTube URL or video ID to download audio
- Uses `youtube_explode_dart` to resolve and download audio streams
- Writes downloaded files to device storage
- Embeds track metadata and artwork using `audiotags`
- Shows download status, progress, and controls

### Theme & Onboarding

- First-launch onboarding flow with illustrated welcome screens
- Light/Dark mode selection in onboarding
- Theme persistence via `hydrated_bloc`
- Clean app presentation and animated selection controls

## Project Structure

- `lib/main.dart` – App entrypoint and theme setup
- `lib/presentation/` – UI screens and navigation flow
  - `home/` – Main tabbed player screen
  - `pages/` – Songs, Favorites, Playlists, Download
  - `intro/` – Onboarding screens
  - `choose_mode/` – Theme selection flow
  - `splash/` – First-launch loading logic
- `lib/core/` – Business logic, configuration, models, and services
  - `models/` – Audio playback, download manager, favorites, playlist service
  - `configs/` – Themes, assets, colors
  - `utils/` – Shared utilities
- `assets/` – Images, fonts, and vector assets used by the UI

## Dependencies

The app uses a variety of Flutter packages for playback, persistence, and UI:

- `flutter_bloc` / `hydrated_bloc` – state management and theme persistence
- `just_audio` / `just_audio_background` – audio playback
- `audio_service` – background audio support
- `hive_flutter` – playlist persistence
- `sqflite` – favorites storage
- `youtube_explode_dart` – YouTube audio download
- `audiotags` – metadata writing for downloaded files
- `audio_metadata_reader` – reading local audio metadata
- `permission_handler` – storage access permissions
- `flutter_svg` – vector asset rendering
- `path_provider` – platform directories

## Setup

### Prerequisites

- Flutter SDK installed
- Android SDK / iOS SDK configured
- `flutter` command available in PATH

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

### Build for release

Android:

```bash
flutter build apk --release
```

iOS:

```bash
flutter build ios --release
```

## Notes

- The app scans local audio from device storage, including the download folder used by the downloader.
- The downloader is currently designed for Android-style storage paths, and permission handling is implemented for Android.
- Local songs and favorites are persisted across app launches.
- Theme selection is stored with `hydrated_bloc`, so the chosen light/dark theme remains after restart.

## Recommended Workflow

1. Launch the app
2. Complete onboarding and choose a theme
3. Use the Songs tab to scan and play local tracks
4. Mark favorites and manage them in the Favorites tab
5. Create playlists and add songs from the Songs screen
6. Use the Download tab to fetch YouTube audio

## Contribution

- Add new supported audio formats in `lib/core/models/files_loader.dart`
- Extend the download manager with additional quality options in `lib/core/models/downloader.dart`
- Improve playback controls in `lib/core/models/audio_player.dart`
- Update UI styles in `lib/core/configs/theme/`
