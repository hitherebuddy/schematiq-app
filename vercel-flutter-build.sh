#!/bin/bash

# Exit on any error
set -e

# 1. Define Flutter version and clone the SDK
FLUTTER_VERSION="3.19.6"
git clone https://github.com/flutter/flutter.git --depth 1 --branch $FLUTTER_VERSION /tmp/flutter

# 2. Add the Flutter tool to the path
export PATH="/tmp/flutter/bin:$PATH"

# 3. Navigate into the frontend directory
cd frontend

# 4. Configure Flutter for web
flutter config --enable-web

# 5. Get dependencies
flutter pub get

# 6. Build the web application
flutter build web --release --base-href /