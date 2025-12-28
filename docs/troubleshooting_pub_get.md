Troubleshooting `flutter pub get` and build failures

If you see `Failed to update packages` or `flutter pub get` fails, try the following steps in order:

1) Check `pubspec.yaml` for mistakes
   - Look for typos or incorrect package names (e.g., `webview_flutter_windows` is not a package on pub.dev).
   - If you added a custom or local package, ensure the source is valid.

2) Run `flutter pub get` and capture output
```powershell
flutter pub get -v
```
The `-v` flag gives more detail about what failed.

3) Fix locked files preventing `flutter clean`
   - Close running apps that may be locking files: Visual Studio, `flutter run` sessions, Explorer windows opened in the project folder.
   - Use Task Manager to kill lingering `dart`, `flutter`, `vcruntime`, or Visual Studio processes.
   - Alternatively reboot the machine to clear handles.

4) Run `flutter clean` then `flutter pub get`
```powershell
flutter clean
flutter pub get
```

If `flutter clean` fails with `Failed to delete a directory` errors (common on Windows when files are open or when OneDrive is syncing), use the included helper script to stop common processes and remove locked directories.

Important: run the script from a separate PowerShell session (not the VS Code integrated terminal) and as Administrator because it may stop IDE processes (such as `Code`) which will terminate your terminal. For safety, close IDEs first if you prefer not to be disconnected.

Run PowerShell as Administrator and execute from the repo root:

```powershell
# Run the cleanup script (optionally skip stopping OneDrive with -SkipOneDrive)
.\scripts\clean_windows_project.ps1 -ProjectRoot .

# then retry
flutter clean
flutter pub get
```

If the script cannot remove files, try rebooting or follow the `Handle` utility steps below.

5) If `pub get` still fails with network issues:
   - Ensure you have a working connection to pub.dev
   - If you're behind a proxy, configure `PUB_HOSTED_URL` and `FLUTTER_STORAGE_BASE_URL` environment variables.

6) Windows-specific: WebView / WebView2
   - If you see WebView initialization errors at runtime (``WebViewPlatform.instance != null``), install Microsoft Edge WebView2 runtime:
     https://developer.microsoft.com/en-us/microsoft-edge/webview2/#download-section

7) When in doubt, paste the verbatim `flutter pub get -v` output in a message and I will analyze it.

If you want, I can also:
- Scan your `pubspec.yaml` and remove or fix invalid packages automatically, or
- Provide a small PowerShell script to help find processes locking files in your project folder.
