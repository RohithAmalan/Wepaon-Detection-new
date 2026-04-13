# Weapon Detection Flutter App

Flutter version of the React Native Weapon Detection mobile app.

## Screens

| Screen | Description |
|--------|-------------|
| `LoginScreen` | Login + IP address + MQTT topic configuration |
| `NormalHealthScreen` | Shown when no weapon detected (SAFE state) |
| `AbnormalHealthScreen` | Shown when weapon detected — live camera feed + ALARM/GATE controls |

## Prerequisites

- Flutter SDK ≥ 3.0 ([Install Flutter](https://docs.flutter.dev/get-started/install))
- Android Studio or Xcode

## Running the App

```bash
cd "Mobile App/WeaponDetectionFlutterApp"
flutter pub get
flutter run
```

## Login Credentials (Hardcoded for testing)

- Username: `1`
- Password: `1`
- IP Address: Enter the IP where `detect.py` is running (e.g. `192.168.1.10`)
- Notification Topic: `WEAPON-NT`
- Shop Topic: `SHOP-TOPIC`

## Technologies Used

| React Native | Flutter Equivalent |
|---|---|
| `AsyncStorage` | `shared_preferences` |
| `react-native-mqtt-new` | `mqtt_client` |
| `react-native-webview` | `webview_flutter` |
| `expo-linear-gradient` | Flutter `LinearGradient` (built-in) |
| `react-native-push-notification` | `firebase_messaging` + `flutter_local_notifications` |
