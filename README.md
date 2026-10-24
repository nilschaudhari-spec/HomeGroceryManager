# Home Grocery Manager

Offline-first Flutter application for household inventory, consumption-based reorder estimates, local reminders, shopping-list tracking, and AdMob monetization.

## Project Status: Build & Source Verified ✅
- **Flutter**: 3.47.2 / **Dart**: 3.13.2 verified.
- **Static Analysis**: `flutter analyze` completed with **0 issues**.
- **Unit Tests**: `flutter test` passed all test cases.
- **Native Scaffolding**: Android & iOS native project structures (Gradle wrapper, Kotlin MainActivity, Xcode project, Runner, LaunchScreen) are generated and configured.

## Implemented Features
- **Flutter Material 3 App UI** for Android and iOS with clean cards, stat widgets, search bar, and filter chips.
- **Local SQLite Database** on the device using `sqflite`; 100% offline-first, no account required, no cloud dependencies.
- **Add, Edit, & Delete Groceries**: Category, quantity, units (`kg`, `g`, `L`, `ml`, `pcs`, `pack`, `bottle`, `dozen`), minimum threshold, daily consumption rate, unit price, and notes.
- **Consumption-based Reorder Estimations**: Automatically calculates estimated days remaining, flags low-stock items, and recommends restock quantities.
- **Shopping List Filter**: Toggle items directly to/from shopping list with dedicated view.
- **Restock Flow**: Quick restock dialog updating inventory quantities and last purchased timestamps.
- **Local Daily Reminders & Alerts**: Configurable daily reminder at user-selected local time using `flutter_local_notifications` and `timezone`.
- **AdMob Monetization**: Integrated AdMob banner in bottom bar and interstitial ad triggered upon restock actions (using official Google test IDs for development).
- **In-App Privacy & Disclosures**: Built-in "About & Privacy" dialog disclosing offline storage and ad compliance.

## Run & Build
1. Check dependencies:
   ```bash
   flutter pub get
   ```
2. Run automated tests:
   ```bash
   flutter test
   ```
3. Run static analysis:
   ```bash
   flutter analyze
   ```
4. Run on a connected device/emulator:
   ```bash
   flutter run
   ```
5. Production builds:
   - **Android**: `flutter build apk --release` or `flutter build appbundle --release`
   - **iOS**: `flutter build ipa --release` (on macOS)

## AdMob Configuration (Before Production Release)
- The app is currently configured with Google's official sample/test ad IDs for development.
- When ready for release:
  - Replace the App ID in [android/app/src/main/AndroidManifest.xml](file:///d:/Nilesh/Nilesh/home_grocery_manager/android/app/src/main/AndroidManifest.xml) and [ios/Runner/Info.plist](file:///d:/Nilesh/Nilesh/home_grocery_manager/ios/Runner/Info.plist).
  - Replace Banner and Interstitial ad unit IDs in [lib/services/ads_service.dart](file:///d:/Nilesh/Nilesh/home_grocery_manager/lib/services/ads_service.dart).

## Architecture & Code Structure
- [lib/models/grocery_item.dart](file:///d:/Nilesh/Nilesh/home_grocery_manager/lib/models/grocery_item.dart): Inventory data model, consumption prediction, runout calculation, and serialization.
- [lib/data/grocery_database.dart](file:///d:/Nilesh/Nilesh/home_grocery_manager/lib/data/grocery_database.dart): Local SQLite persistence (`sqflite`).
- [lib/services/notification_service.dart](file:///d:/Nilesh/Nilesh/home_grocery_manager/lib/services/notification_service.dart): Local scheduled notifications and low-stock alerts.
- [lib/services/ads_service.dart](file:///d:/Nilesh/Nilesh/home_grocery_manager/lib/services/ads_service.dart): AdMob banner & interstitial integration.
- [lib/screens/home_screen.dart](file:///d:/Nilesh/Nilesh/home_grocery_manager/lib/screens/home_screen.dart): Main dashboard with stats, search, filter chips, grocery list, restock flow, and AdMob banner.
- [lib/screens/item_form_screen.dart](file:///d:/Nilesh/Nilesh/home_grocery_manager/lib/screens/item_form_screen.dart): Form to create and edit groceries, configure reminder time and frequency.
- [test/grocery_item_test.dart](file:///d:/Nilesh/Nilesh/home_grocery_manager/test/grocery_item_test.dart): Unit tests for calculations, runout predictions, and map serialization.
