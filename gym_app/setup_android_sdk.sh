#!/bin/bash

echo "==================================="
echo "Android SDK Setup for Flutter"
echo "==================================="

# Install Java
echo "Installing Java..."
sudo apt update
sudo apt install openjdk-17-jdk unzip -y

# Create SDK directory
echo "Creating Android SDK directory..."
mkdir -p ~/Android/Sdk
cd ~/Android/Sdk

# Download command line tools
echo "Downloading Android command line tools..."
wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip

# Extract
echo "Extracting tools..."
unzip -q commandlinetools-linux-11076708_latest.zip

# Organize directories
mkdir -p cmdline-tools/latest
mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null

# Set environment variables
echo "Setting environment variables..."
if ! grep -q "ANDROID_HOME" ~/.bashrc; then
    echo '' >> ~/.bashrc
    echo '# Android SDK' >> ~/.bashrc
    echo 'export ANDROID_HOME=$HOME/Android/Sdk' >> ~/.bashrc
    echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin' >> ~/.bashrc
    echo 'export PATH=$PATH:$ANDROID_HOME/platform-tools' >> ~/.bashrc
fi

# Source the changes
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Install required SDK components
echo "Installing SDK components..."
cd ~/Android/Sdk/cmdline-tools/latest/bin
./sdkmanager --sdk_root=$ANDROID_HOME "platform-tools" "platforms;android-34" "build-tools;34.0.0" "platforms;android-33"

# Accept licenses
echo "Accepting licenses..."
yes | ./sdkmanager --sdk_root=$ANDROID_HOME --licenses

# Configure Flutter
echo "Configuring Flutter..."
flutter config --android-sdk ~/Android/Sdk

# Cleanup
cd ~/Android/Sdk
rm -f commandlinetools-linux-*.zip

echo ""
echo "==================================="
echo "✓ Android SDK installed!"
echo "==================================="
echo ""
echo "Please run: source ~/.bashrc"
echo "Then run: flutter doctor"
echo ""
echo "To build your APK, run:"
echo "  cd ~/gym_app"
echo "  flutter build apk --release"
echo ""
