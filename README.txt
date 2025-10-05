
MMart Fun - Xcode Project (source)
---------------------------------

What's included:
- SwiftUI source file: Content swift (main app UI & logic).
- README with instructions how to add sound assets and build .ipa.

Important notes before building:
1. Please download two audio files and add them to the Xcode project bundle (drag into Project navigator):
   - clap.mp3  (applause sound)  - example free source: https://cdn.pixabay.com/download/audio/2022/03/15/audio_052d6e69a0.mp3?filename=small-crowd-applause-82873.mp3
   - aww.mp3   (awww / pity sound) - example free source: https://cdn.pixabay.com/download/audio/2022/03/15/audio_16f1f3c0ce.mp3?filename=aww-86042.mp3

2. Colors and asset names:
   The project expects asset colors named PrimaryLight and PrimaryDark in Assets catalog. You can create them or edit the Swift file to use system colors.

Build steps (on Mac, Xcode):
- Create a new SwiftUI App in Xcode, replace ContentView.swift / App code with the provided Swift file content.
- Add clap.mp3 and aww.mp3 to the app target (check 'Add to target').
- In Signing & Capabilities, select your Team (Apple ID) or use automatic signing.
- Build and run on a device or Archive -> Export -> Ad Hoc or Development to create .ipa.

If you only have Windows:
- You still need a built .ipa file. You can either:
  1) Ask a friend with a Mac to build/archive and send you the .ipa.
  2) Use a cloud Mac build service (GitHub Actions macOS runners) to build and produce .ipa (requires Apple Developer credentials for signing).
  3) Alternatively, I can prepare a GitHub Actions workflow to build automatically — you'll need to provide Apple Developer signing credentials / certificate and provisioning profile.

How to install signed .ipa on Windows using Sideloadly (after you get a signed .ipa):
- Download and install iTunes & iCloud for Windows (official versions).
- Download Sideloadly: https://sideloadly.io/
- Connect iPhone via USB, open Sideloadly, drag signed .ipa, sign with your Apple ID if needed and press Start.

If you want, I can:
- Produce a GitHub Actions workflow file to build and sign the .ipa for you (you will need to provide Apple Developer certificates and provisioning profiles as secrets).
- Or, provide step-by-step assistance to generate a signed .ipa using a Mac, or guide you to sign & install with Sideloadly on Windows.

