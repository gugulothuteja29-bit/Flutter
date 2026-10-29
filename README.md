# College Placement Tracker

A Flutter web-compatible task tracker for placement preparation. Add, edit, filter, and delete placement tasks.

## Requirements

- Flutter stable SDK
- VS Code with the Flutter and Dart extensions
- Git (for pushing to GitHub)

## Run locally in VS Code

1. Extract this ZIP file.
2. Open the extracted `college_placement_tracker_vercel` folder in VS Code.
3. Open **Terminal → New Terminal**.
4. Run:

   ```bash
   flutter doctor
   flutter pub get
   flutter run -d chrome
   ```

5. If Chrome is not detected, run `flutter devices` and choose an available browser device.

## Build for the web locally

```bash
flutter build web
```

Output: `build/web/`. To test the production build locally, use a static server to serve that folder.

## Deploy to Vercel

1. Push this project to a GitHub repository.
2. In Vercel, import the repository and choose branch `main`.
3. Keep the project root as `./`.
4. Vercel reads `vercel.json`; it installs Flutter in the build environment, runs `flutter pub get`, builds Flutter web, and publishes `build/web`.
5. Check the deployment build logs if it fails.

## Data storage note

This starter uses `shared_preferences`, which supports web. Task data is saved in the current browser's local storage. It is not a server database and will not synchronize across browsers or devices. This starter does not use SQLite on web.
