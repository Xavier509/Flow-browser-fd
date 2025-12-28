import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/browser_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/browser_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('workspaces');
  await Hive.openBox('bookmarks');
  await Hive.openBox('history');
  await Hive.openBox('notes');
  await Hive.openBox('todos');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Defer provider initialization until after widgets are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final auth = context.read<AuthProvider>();
        final browser = context.read<BrowserProvider>();
        auth.initialize();
        // If already signed in, sync remote data
        if (auth.isAuthenticated) {
          browser.syncHistoryFromSupabase();
          browser.syncNotesFromSupabase();
          browser.syncTodosFromSupabase();
        }
        // Listen for auth changes to trigger sync
        auth.addListener(() {
          if (auth.isAuthenticated) {
            browser.syncHistoryFromSupabase();
            browser.syncNotesFromSupabase();
            browser.syncTodosFromSupabase();
          }
        });
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BrowserProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          final light = ThemeData(
            brightness: Brightness.light,
            primaryColor: AppConstants.primaryColor,
            scaffoldBackgroundColor: Colors.white,
            colorScheme: ColorScheme.fromSwatch().copyWith(secondary: AppConstants.secondaryColor),
            appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black),
          );

          final dark = ThemeData(
            brightness: Brightness.dark,
            primaryColor: AppConstants.primaryColor,
            scaffoldBackgroundColor: AppConstants.darkBackground,
            colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(secondary: AppConstants.secondaryColor),
            appBarTheme: AppBarTheme(backgroundColor: AppConstants.surfaceColor),
          );

          return MaterialApp(
            title: 'Flow Browser',
            debugShowCheckedModeBanner: false,
            theme: light,
            darkTheme: dark,
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const BrowserScreen(),
          );
        },
      ),
    );
  }
}
