#!/bin/bash

set -e  # Exit on any error

# Create build directory structure
mkdir -p build/tmp
cd build

# Clean up old files
rm -rf VideoCompressor.app
rm -f tmp/VideoCompressor

# Download and build FFmpeg if not already present
if [ ! -f "ffmpeg" ]; then
    echo "Copying FFmpeg..."
    cp /Users/liamz/.nix-profile/bin/ffmpeg .
    chmod +x ffmpeg
fi

# Build the app
echo "Building VideoCompressor..."
cd ..  # Go back to root directory for make
make clean
make
cd build  # Go back to build directory

# Move binary to tmp
mv ../VideoCompressor tmp/

# Create app bundle structure
echo "Creating app bundle..."
mkdir -p VideoCompressor.app/Contents/MacOS
mkdir -p VideoCompressor.app/Contents/Resources

# Copy files into app bundle
echo "Copying files..."
cp tmp/VideoCompressor VideoCompressor.app/Contents/MacOS/
cp ffmpeg VideoCompressor.app/Contents/MacOS/
chmod +x VideoCompressor.app/Contents/MacOS/ffmpeg
chmod +x VideoCompressor.app/Contents/MacOS/VideoCompressor

# Create Info.plist
echo "Creating Info.plist..."
cat > VideoCompressor.app/Contents/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>VideoCompressor</string>
    <key>CFBundleIdentifier</key>
    <string>com.videocompressor.app</string>
    <key>CFBundleName</key>
    <string>VideoCompressor</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
EOF

# Verify the app bundle
echo "Verifying app bundle..."
if [ ! -f "VideoCompressor.app/Contents/MacOS/VideoCompressor" ]; then
    echo "Error: VideoCompressor executable not found in app bundle"
    exit 1
fi

if [ ! -f "VideoCompressor.app/Contents/MacOS/ffmpeg" ]; then
    echo "Error: FFmpeg not found in app bundle"
    exit 1
fi

if [ ! -f "VideoCompressor.app/Contents/Info.plist" ]; then
    echo "Error: Info.plist not found in app bundle"
    exit 1
fi

# Clean up temporary files
echo "Cleaning up..."
rm -f tmp/VideoCompressor
rm -f ffmpeg

echo "Build complete! App is in VideoCompressor.app"
echo "To run: open VideoCompressor.app"
echo "If it doesn't open, try:"
echo "1. Right-click and select 'Open'"
echo "2. Or run: xattr -cr VideoCompressor.app" 