#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/flutter/bin:$PATH"
if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK not found at $HOME/flutter/bin/flutter"
  exit 1
fi
flutter config --enable-web
flutter pub get
flutter build web --release
