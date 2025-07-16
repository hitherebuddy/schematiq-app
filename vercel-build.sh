#!/bin/bash

# Exit on any error
set -e

# 1. Clone the specific version of Flutter SDK we need
echo "--- Cloning Flutter SDK ---"
git clone https://github.com/flutter/flutter.git --depth 1 --branch 3.19.6 /tmp/flutter

# 2. Add the cloned Flutter tool to the system's PATH
export PATH="/tmp/flutter/bin:$PATH"

# 3. Verify Flutter is available
echo "--- Verifying Flutter Installation ---"
flutter --version

# 4. Navigate into the frontend project directory
echo "--- Navigating to frontend directory ---"
cd frontend

# 5. Get Flutter dependencies
echo "--- Running flutter pub get ---"
flutter pub get

# 6. Build the Flutter web application for release
echo "--- Building Flutter for Web ---"
flutter build web --release --base-href /

echo "--- Build Complete ---"