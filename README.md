# oba-macos
A native macOS menu bar application for tracking bus arrivals using the OneBusAway API.

## Overview
This app lives in your Mac's menu bar and provides quick access to incoming buses for your saved stops. It is built natively using SwiftUI and modern macOS APIs.

![Popover Screenshot](screenshots/popover.png)

## Features
- **Live Arrivals**: See real-time predicted and scheduled bus arrivals from the OneBusAway network.
- **Location-Based**: Uses your computer's location to find nearby bus stops automatically.
- **Customizable**: Select specific routes from your favorite stops to filter out buses you don't take.

## Setup
1. Clone the repository and open `oba-macos.xcodeproj` in Xcode.
2. Build and run the project.
3. Upon first launch, the Settings window will open. Click the "Settings" button in the menu bar popover if it does not.
4. Input your OneBusAway API Key. 
5. Grant location permissions, find nearby stops, and click the star icon to save specific stops and routes.

## Technologies
- Swift 5+
- SwiftUI (`MenuBarExtra`, `Window`)
- OneBusAway REST API
- CoreLocation for nearby stops
