## Windows WebView2 and dev setup 🪟

If you plan to run Flow Browser on Windows, ensure the following:

1. Add the Windows webview platform package and fetch dependencies:

```powershell
flutter pub add webview_flutter_windows
flutter pub get
```

2. Install Microsoft Edge WebView2 runtime (required by the Windows webview implementation):

- Download directly from Microsoft: https://developer.microsoft.com/en-us/microsoft-edge/webview2/#download-section
- Use the Evergreen installer for auto-updates.

3. Build and run the app:

```powershell
flutter build windows
.
# Or during development
flutter run -d windows
```

If the WebView platform is missing or WebView2 is not installed, the app will show a red error panel with an "Install WebView2" button and an actionable message.
