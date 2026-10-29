#!/usr/bin/env bash
set -euo pipefail
if ! command -v flutter >/dev/null 2>&1; then
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$HOME/flutter"
  export PATH="$HOME/flutter/bin:$PATH"
  flutter --version
fi
export PATH="$HOME/flutter/bin:$PATH"
flutter pub get
