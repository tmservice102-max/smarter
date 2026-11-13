# IPTV Smarter Pro - Flutter app (iPhone + Android)

New app written in Flutter. It uses the same admin panel (smartersapp.org).

## What works (phase 1)
- Login: Xtream Codes (with the server list from the panel), M3U playlist,
  activation code and device ID (both from the panel). Several saved users.
- Live TV, Movies, Series: categories, favorites, recently watched, search, sort.
- Player: live channels (next/previous, channel list, now and next program),
  movies and episodes (resume where you stopped, next episode),
  audio and subtitle choice. Plays .ts, .m3u8, .mkv and .mp4.
- TV guide per channel, account status and expiry, notifications from the panel,
  report a problem, privacy policy and terms, 24-hour time.

- Catch-up TV (watch past programs on channels that support it) and a full
  TV guide by day.
- Downloads of movies and episodes for offline viewing (while the app is open).
- App icon and launch screen.

## Not in this version yet
Multi-screen, the extra home themes, ads, push notifications, OpenVPN, Chromecast.

## Codemagic workflows
- `ios-check`: builds the iPhone app without signing, to check it compiles.
- `android-release`: builds an Android APK.
- `ios-release`: signed iPhone build sent to TestFlight (needs the Apple account).

## Settings to check
`lib/config.dart`: app name, panel URL, package name (must match "Package name"
in the panel settings, or the panel replies "Invalid Package Name").

## Build for iPhone without a Mac (Codemagic)
1. Apple Developer account ($99/year). At developer.apple.com create the App ID
   `com.smartersapp.iptvSmarter` (or your own, then change it in `codemagic.yaml`
   and in Xcode project settings).
2. In App Store Connect create the app, and create an API key
   (Users and Access > Integrations).
3. Put this folder in a GitHub repository.
4. At codemagic.io sign in with GitHub, add the repository, add the API key under
   Teams > Integrations > App Store Connect with the name `asc_key`.
5. Start the "iPhone release (TestFlight)" workflow. The app arrives in TestFlight,
   install TestFlight on the iPhone to test it.

## Test on Android from Windows
Install Flutter (flutter.dev), then in this folder:
`flutter pub get` then `flutter run` (phone connected), or `flutter build apk`.
